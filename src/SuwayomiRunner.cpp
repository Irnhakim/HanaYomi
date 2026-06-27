#include "SuwayomiRunner.h"
#include <QTcpServer>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QDir>
#include <QDebug>
#include <QProcessEnvironment>

SuwayomiRunner::SuwayomiRunner(QObject *parent)
    : QObject(parent)
    , m_healthTimer(new QTimer(this))
    , m_nam(new QNetworkAccessManager(this))
{
    connect(m_healthTimer, &QTimer::timeout, this, &SuwayomiRunner::checkHealth);
}

SuwayomiRunner::~SuwayomiRunner()
{
    stop();
}

int SuwayomiRunner::getFreePort()
{
    QTcpServer server;
    if (server.listen(QHostAddress::LocalHost, 0)) {
        int freePort = server.serverPort();
        server.close();
        return freePort;
    }
    return 4567; // default fallback
}
QString SuwayomiRunner::findLibDir()
{
    // Try development/build locations first
    QStringList devBuildDirs = {
        "/home/hakim/Projects/Suwayomi-Server/server/build/install/server/lib",
        "/home/hakim/Projects/HanaYomi/suwayomi-lib"
    };
    for (const QString &devBuildDir : devBuildDirs) {
        if (QDir(devBuildDir).exists()) {
            return devBuildDir;
        }
    }

    // Try app directory relative paths (for clickable build & deployment)
    QString appDir = qgetenv("APP_DIR");
    if (appDir.isEmpty()) {
        appDir = QCoreApplication::applicationDirPath();
    }
    QString appDirLib = appDir + "/suwayomi-lib";
    if (QDir(appDirLib).exists()) {
        return appDirLib;
    }

    return QString();
}

void SuwayomiRunner::start()
{
    if (m_isRunning) return;

    QString libDir = findLibDir();
    if (libDir.isEmpty()) {
        qWarning() << "suwayomi-lib directory not found!";
        emit failed("suwayomi-lib directory not found. Please build or copy it to the application directory.");
        return;
    }

    m_port = getFreePort();
    emit portChanged(m_port);
    emit baseUrlChanged(baseUrl());

    QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QString rootDir = appDataDir + "/Tachidesk";
    QDir().mkpath(rootDir);
    QDir().mkpath(rootDir + "/tmp");

    qDebug() << "Starting Suwayomi backend on port" << m_port << "with root dir" << rootDir;

    m_process = new QProcess(this);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &SuwayomiRunner::handleProcessFinished);
    connect(m_process, &QProcess::errorOccurred, this, &SuwayomiRunner::handleProcessError);
    connect(m_process, &QProcess::readyReadStandardOutput, this, &SuwayomiRunner::readProcessOutput);
    connect(m_process, &QProcess::readyReadStandardError, this, &SuwayomiRunner::readProcessOutput);
    QStringList arguments;
    arguments << QString("-Dsuwayomi.tachidesk.config.server.port=%1").arg(m_port);
    arguments << "-Dsuwayomi.tachidesk.config.server.ip=127.0.0.1";
    arguments << QString("-Dsuwayomi.tachidesk.config.server.rootDir=%1").arg(rootDir);
    arguments << QString("-Djava.io.tmpdir=%1/tmp").arg(rootDir);
    arguments << "-Dsuwayomi.tachidesk.config.server.initialOpenInBrowserEnabled=false";
    arguments << "-Dsuwayomi.tachidesk.config.server.kcefEnabled=false";
    arguments << "-Dsuwayomi.tachidesk.config.server.extensionRepos=[\"https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json\"]";
    arguments << "-cp" << QString("%1/*").arg(libDir);
    arguments << "suwayomi.tachidesk.MainKt";

    QString appDir = qgetenv("APP_DIR");
    if (appDir.isEmpty()) {
        appDir = QCoreApplication::applicationDirPath();
    }

    QString javaExec = "java";
    QStringList possibleJavaPaths = {
        appDir + "/jre/bin/java",
        "/home/hakim/Projects/HanaYomi/jre/bin/java"
    };
    for (const QString &path : possibleJavaPaths) {
        if (QFile::exists(path)) {
            javaExec = path;
            break;
        }
    }

    qDebug() << "Using Java executable:" << javaExec;

    // Ensure Java binary has executable permissions (CMake install directory sometimes strips it)
    if (javaExec != "java" && QFile::exists(javaExec)) {
        QFile::Permissions perms = QFile::permissions(javaExec);
        if (!(perms & QFile::ExeUser)) {
            qDebug() << "Enforcing executable permissions on:" << javaExec;
            QFile::setPermissions(javaExec, perms | QFile::ExeUser | QFile::ExeOwner | QFile::ExeGroup | QFile::ExeOther);
        }
    }

    m_process->start(javaExec, arguments);

    m_isRunning = true;
    emit isRunningChanged(m_isRunning);

    m_isReady = false;
    m_healthCheckAttempts = 0;
    m_healthTimer->start(1000); // Check every second
}

void SuwayomiRunner::stop()
{
    if (m_healthTimer->isActive()) {
        m_healthTimer->stop();
    }

    if (m_process) {
        qDebug() << "Stopping Suwayomi process...";
        m_process->terminate();
        if (!m_process->waitForFinished(3000)) {
            m_process->kill();
        }
        delete m_process;
        m_process = nullptr;
    }

    if (m_isRunning) {
        m_isRunning = false;
        m_isReady = false;
        emit isRunningChanged(m_isRunning);
        emit stopped();
    }
}

void SuwayomiRunner::checkHealth()
{
    m_healthCheckAttempts++;
    if (m_healthCheckAttempts > 45) { // 45 seconds timeout
        qWarning() << "Suwayomi health check timed out!";
        m_healthTimer->stop();
        emit failed("Suwayomi server failed to start within 45 seconds.");
        stop();
        return;
    }

    QUrl url(QString("http://127.0.0.1:%1/api/v1/about").arg(m_port));
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);

    QNetworkReply *reply = m_nam->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            qDebug() << "Suwayomi backend is healthy and ready!";
            m_healthTimer->stop();
            m_isReady = true;
            emit ready();
        }
    });
}

void SuwayomiRunner::handleProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qDebug() << "Suwayomi process finished. Exit code:" << exitCode << "Status:" << exitStatus;
    stop();
}

void SuwayomiRunner::handleProcessError(QProcess::ProcessError error)
{
    qWarning() << "Suwayomi process error occurred:" << error;
    if (error == QProcess::FailedToStart) {
        emit failed("Failed to start 'java' process. Please verify Java JRE/JDK is installed.");
        stop();
    }
}

void SuwayomiRunner::readProcessOutput()
{
    if (!m_process) return;
    QByteArray out = m_process->readAllStandardOutput();
    QByteArray err = m_process->readAllStandardError();
    if (!out.isEmpty()) qDebug() << "Suwayomi [STDOUT]:" << out.trimmed();
    if (!err.isEmpty()) qDebug() << "Suwayomi [STDERR]:" << err.trimmed();
}
