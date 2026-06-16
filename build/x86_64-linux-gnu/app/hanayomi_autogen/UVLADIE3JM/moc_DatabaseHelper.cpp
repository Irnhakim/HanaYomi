/****************************************************************************
** Meta object code from reading C++ file 'DatabaseHelper.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.12.8)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../../src/DatabaseHelper.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'DatabaseHelper.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.12.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
struct qt_meta_stringdata_DatabaseHelper_t {
    QByteArrayData data[47];
    char stringdata0[607];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_DatabaseHelper_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_DatabaseHelper_t qt_meta_stringdata_DatabaseHelper = {
    {
QT_MOC_LITERAL(0, 0, 14), // "DatabaseHelper"
QT_MOC_LITERAL(1, 15, 14), // "libraryChanged"
QT_MOC_LITERAL(2, 30, 0), // ""
QT_MOC_LITERAL(3, 31, 14), // "historyChanged"
QT_MOC_LITERAL(4, 46, 15), // "getLibraryManga"
QT_MOC_LITERAL(5, 62, 19), // "insertOrUpdateManga"
QT_MOC_LITERAL(6, 82, 8), // "mangaMap"
QT_MOC_LITERAL(7, 91, 14), // "toggleFavorite"
QT_MOC_LITERAL(8, 106, 7), // "mangaId"
QT_MOC_LITERAL(9, 114, 8), // "favorite"
QT_MOC_LITERAL(10, 123, 12), // "getMangaById"
QT_MOC_LITERAL(11, 136, 20), // "getChaptersByMangaId"
QT_MOC_LITERAL(12, 157, 22), // "insertOrUpdateChapters"
QT_MOC_LITERAL(13, 180, 8), // "chapters"
QT_MOC_LITERAL(14, 189, 15), // "markChapterRead"
QT_MOC_LITERAL(15, 205, 9), // "chapterId"
QT_MOC_LITERAL(16, 215, 6), // "isRead"
QT_MOC_LITERAL(17, 222, 8), // "lastPage"
QT_MOC_LITERAL(18, 231, 10), // "getHistory"
QT_MOC_LITERAL(19, 242, 13), // "upsertHistory"
QT_MOC_LITERAL(20, 256, 11), // "chapterName"
QT_MOC_LITERAL(21, 268, 10), // "chapterNum"
QT_MOC_LITERAL(22, 279, 10), // "mangaTitle"
QT_MOC_LITERAL(23, 290, 12), // "thumbnailUrl"
QT_MOC_LITERAL(24, 303, 13), // "removeHistory"
QT_MOC_LITERAL(25, 317, 9), // "historyId"
QT_MOC_LITERAL(26, 327, 10), // "getUpdates"
QT_MOC_LITERAL(27, 338, 13), // "getCategories"
QT_MOC_LITERAL(28, 352, 14), // "createCategory"
QT_MOC_LITERAL(29, 367, 4), // "name"
QT_MOC_LITERAL(30, 372, 14), // "deleteCategory"
QT_MOC_LITERAL(31, 387, 2), // "id"
QT_MOC_LITERAL(32, 390, 18), // "setMangaCategories"
QT_MOC_LITERAL(33, 409, 11), // "categoryIds"
QT_MOC_LITERAL(34, 421, 18), // "getMangaCategories"
QT_MOC_LITERAL(35, 440, 23), // "getLibraryMangaFiltered"
QT_MOC_LITERAL(36, 464, 10), // "categoryId"
QT_MOC_LITERAL(37, 475, 7), // "sortCol"
QT_MOC_LITERAL(38, 483, 9), // "sortOrder"
QT_MOC_LITERAL(39, 493, 12), // "filterStatus"
QT_MOC_LITERAL(40, 506, 14), // "renameCategory"
QT_MOC_LITERAL(41, 521, 7), // "newName"
QT_MOC_LITERAL(42, 529, 15), // "getLibraryCount"
QT_MOC_LITERAL(43, 545, 20), // "getReadChaptersCount"
QT_MOC_LITERAL(44, 566, 13), // "getGenreStats"
QT_MOC_LITERAL(45, 580, 12), // "clearHistory"
QT_MOC_LITERAL(46, 593, 13) // "clearAllCache"

    },
    "DatabaseHelper\0libraryChanged\0\0"
    "historyChanged\0getLibraryManga\0"
    "insertOrUpdateManga\0mangaMap\0"
    "toggleFavorite\0mangaId\0favorite\0"
    "getMangaById\0getChaptersByMangaId\0"
    "insertOrUpdateChapters\0chapters\0"
    "markChapterRead\0chapterId\0isRead\0"
    "lastPage\0getHistory\0upsertHistory\0"
    "chapterName\0chapterNum\0mangaTitle\0"
    "thumbnailUrl\0removeHistory\0historyId\0"
    "getUpdates\0getCategories\0createCategory\0"
    "name\0deleteCategory\0id\0setMangaCategories\0"
    "categoryIds\0getMangaCategories\0"
    "getLibraryMangaFiltered\0categoryId\0"
    "sortCol\0sortOrder\0filterStatus\0"
    "renameCategory\0newName\0getLibraryCount\0"
    "getReadChaptersCount\0getGenreStats\0"
    "clearHistory\0clearAllCache"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_DatabaseHelper[] = {

 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
      26,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       2,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    0,  144,    2, 0x06 /* Public */,
       3,    0,  145,    2, 0x06 /* Public */,

 // methods: name, argc, parameters, tag, flags
       4,    0,  146,    2, 0x02 /* Public */,
       5,    1,  147,    2, 0x02 /* Public */,
       7,    2,  150,    2, 0x02 /* Public */,
      10,    1,  155,    2, 0x02 /* Public */,
      11,    1,  158,    2, 0x02 /* Public */,
      12,    2,  161,    2, 0x02 /* Public */,
      14,    3,  166,    2, 0x02 /* Public */,
      14,    2,  173,    2, 0x22 /* Public | MethodCloned */,
      18,    0,  178,    2, 0x02 /* Public */,
      19,    6,  179,    2, 0x02 /* Public */,
      24,    1,  192,    2, 0x02 /* Public */,
      26,    0,  195,    2, 0x02 /* Public */,
      27,    0,  196,    2, 0x02 /* Public */,
      28,    1,  197,    2, 0x02 /* Public */,
      30,    1,  200,    2, 0x02 /* Public */,
      32,    2,  203,    2, 0x02 /* Public */,
      34,    1,  208,    2, 0x02 /* Public */,
      35,    4,  211,    2, 0x02 /* Public */,
      40,    2,  220,    2, 0x02 /* Public */,
      42,    0,  225,    2, 0x02 /* Public */,
      43,    0,  226,    2, 0x02 /* Public */,
      44,    0,  227,    2, 0x02 /* Public */,
      45,    0,  228,    2, 0x02 /* Public */,
      46,    0,  229,    2, 0x02 /* Public */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void,

 // methods: parameters
    QMetaType::QVariantList,
    QMetaType::Bool, QMetaType::QVariantMap,    6,
    QMetaType::Bool, QMetaType::QString, QMetaType::Bool,    8,    9,
    QMetaType::QVariantMap, QMetaType::QString,    8,
    QMetaType::QVariantList, QMetaType::QString,    8,
    QMetaType::Bool, QMetaType::QVariantList, QMetaType::QString,   13,    8,
    QMetaType::Bool, QMetaType::QString, QMetaType::Bool, QMetaType::Int,   15,   16,   17,
    QMetaType::Bool, QMetaType::QString, QMetaType::Bool,   15,   16,
    QMetaType::QVariantList,
    QMetaType::Bool, QMetaType::QString, QMetaType::QString, QMetaType::QString, QMetaType::Float, QMetaType::QString, QMetaType::QString,   15,    8,   20,   21,   22,   23,
    QMetaType::Bool, QMetaType::QString,   25,
    QMetaType::QVariantList,
    QMetaType::QVariantList,
    QMetaType::Bool, QMetaType::QString,   29,
    QMetaType::Bool, QMetaType::Int,   31,
    QMetaType::Bool, QMetaType::QString, QMetaType::QVariantList,    8,   33,
    QMetaType::QVariantList, QMetaType::QString,    8,
    QMetaType::QVariantList, QMetaType::Int, QMetaType::QString, QMetaType::QString, QMetaType::QString,   36,   37,   38,   39,
    QMetaType::Bool, QMetaType::Int, QMetaType::QString,   31,   41,
    QMetaType::Int,
    QMetaType::Int,
    QMetaType::QVariantList,
    QMetaType::Bool,
    QMetaType::Bool,

       0        // eod
};

void DatabaseHelper::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<DatabaseHelper *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->libraryChanged(); break;
        case 1: _t->historyChanged(); break;
        case 2: { QVariantList _r = _t->getLibraryManga();
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 3: { bool _r = _t->insertOrUpdateManga((*reinterpret_cast< const QVariantMap(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 4: { bool _r = _t->toggleFavorite((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< bool(*)>(_a[2])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 5: { QVariantMap _r = _t->getMangaById((*reinterpret_cast< const QString(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 6: { QVariantList _r = _t->getChaptersByMangaId((*reinterpret_cast< const QString(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 7: { bool _r = _t->insertOrUpdateChapters((*reinterpret_cast< const QVariantList(*)>(_a[1])),(*reinterpret_cast< const QString(*)>(_a[2])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 8: { bool _r = _t->markChapterRead((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< bool(*)>(_a[2])),(*reinterpret_cast< int(*)>(_a[3])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 9: { bool _r = _t->markChapterRead((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< bool(*)>(_a[2])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 10: { QVariantList _r = _t->getHistory();
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 11: { bool _r = _t->upsertHistory((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< const QString(*)>(_a[2])),(*reinterpret_cast< const QString(*)>(_a[3])),(*reinterpret_cast< float(*)>(_a[4])),(*reinterpret_cast< const QString(*)>(_a[5])),(*reinterpret_cast< const QString(*)>(_a[6])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 12: { bool _r = _t->removeHistory((*reinterpret_cast< const QString(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 13: { QVariantList _r = _t->getUpdates();
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 14: { QVariantList _r = _t->getCategories();
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 15: { bool _r = _t->createCategory((*reinterpret_cast< const QString(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 16: { bool _r = _t->deleteCategory((*reinterpret_cast< int(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 17: { bool _r = _t->setMangaCategories((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< const QVariantList(*)>(_a[2])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 18: { QVariantList _r = _t->getMangaCategories((*reinterpret_cast< const QString(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 19: { QVariantList _r = _t->getLibraryMangaFiltered((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< const QString(*)>(_a[2])),(*reinterpret_cast< const QString(*)>(_a[3])),(*reinterpret_cast< const QString(*)>(_a[4])));
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 20: { bool _r = _t->renameCategory((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< const QString(*)>(_a[2])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 21: { int _r = _t->getLibraryCount();
            if (_a[0]) *reinterpret_cast< int*>(_a[0]) = std::move(_r); }  break;
        case 22: { int _r = _t->getReadChaptersCount();
            if (_a[0]) *reinterpret_cast< int*>(_a[0]) = std::move(_r); }  break;
        case 23: { QVariantList _r = _t->getGenreStats();
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 24: { bool _r = _t->clearHistory();
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 25: { bool _r = _t->clearAllCache();
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (DatabaseHelper::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&DatabaseHelper::libraryChanged)) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (DatabaseHelper::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&DatabaseHelper::historyChanged)) {
                *result = 1;
                return;
            }
        }
    }
}

QT_INIT_METAOBJECT const QMetaObject DatabaseHelper::staticMetaObject = { {
    &QObject::staticMetaObject,
    qt_meta_stringdata_DatabaseHelper.data,
    qt_meta_data_DatabaseHelper,
    qt_static_metacall,
    nullptr,
    nullptr
} };


const QMetaObject *DatabaseHelper::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *DatabaseHelper::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_DatabaseHelper.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int DatabaseHelper::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 26)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 26;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 26)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 26;
    }
    return _id;
}

// SIGNAL 0
void DatabaseHelper::libraryChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void DatabaseHelper::historyChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
