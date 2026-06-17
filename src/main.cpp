#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQmlNetworkAccessManagerFactory>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QDir>
#include "MangaDexSource.h"
#include "DatabaseHelper.h"

// Factory to inject User-Agent globally into all QML network requests (like Image loading)
class CustomNetworkAccessManager : public QNetworkAccessManager
{
public:
    explicit CustomNetworkAccessManager(QObject *parent = nullptr) : QNetworkAccessManager(parent) {}
protected:
    QNetworkReply *createRequest(Operation op, const QNetworkRequest &request, QIODevice *outgoingData = nullptr) override
    {
        QNetworkRequest req = request;
        req.setRawHeader("User-Agent", "HanaYomi/1.0.0 (contact@hanayomi.app)");
        return QNetworkAccessManager::createRequest(op, req, outgoingData);
    }
};

class CustomNetworkAccessManagerFactory : public QQmlNetworkAccessManagerFactory
{
public:
    QNetworkAccessManager *create(QObject *parent) override
    {
        return new CustomNetworkAccessManager(parent);
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("HanaYomi");
    app.setOrganizationName("hakim");

    // Initialize backend services
    MangaDexSource mangaDex;
    DatabaseHelper db;

    if (!db.initialize()) {
        qCritical() << "Failed to initialize database!";
        return 1;
    }

    QQuickView view;
    view.engine()->setNetworkAccessManagerFactory(new CustomNetworkAccessManagerFactory());

    // Register C++ objects as QML context properties
    view.engine()->rootContext()->setContextProperty("mangaDex", &mangaDex);
    view.engine()->rootContext()->setContextProperty("db", &db);

    // Load main QML file
    QString qmlPath = QCoreApplication::applicationDirPath() + "/qml/Main.qml";
    view.setSource(QUrl::fromLocalFile(qmlPath));
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.show();

    if (view.status() == QQuickView::Error) {
        qCritical() << "Failed to load QML!";
        return 1;
    }

    return app.exec();
}
