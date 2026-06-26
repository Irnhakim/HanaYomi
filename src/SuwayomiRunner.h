#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class SuwayomiRunner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)
    Q_PROPERTY(int port READ port NOTIFY portChanged)
    Q_PROPERTY(QString baseUrl READ baseUrl NOTIFY baseUrlChanged)

public:
    explicit SuwayomiRunner(QObject *parent = nullptr);
    ~SuwayomiRunner();

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

    bool isRunning() const { return m_isRunning; }
    int port() const { return m_port; }
    QString baseUrl() const { return QString("http://127.0.0.1:%1").arg(m_port); }

signals:
    void ready();
    void failed(const QString &error);
    void stopped();
    void isRunningChanged(bool isRunning);
    void portChanged(int port);
    void baseUrlChanged(const QString &baseUrl);

private slots:
    void checkHealth();
    void handleProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void handleProcessError(QProcess::ProcessError error);
    void readProcessOutput();

private:
    int getFreePort();
    QString findLibDir();

    QProcess *m_process = nullptr;
    int m_port = 0;
    bool m_isRunning = false;
    bool m_isReady = false;
    QTimer *m_healthTimer = nullptr;
    QNetworkAccessManager *m_nam = nullptr;
    int m_healthCheckAttempts = 0;
};
