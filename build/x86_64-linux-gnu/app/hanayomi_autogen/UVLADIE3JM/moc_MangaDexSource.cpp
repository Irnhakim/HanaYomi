/****************************************************************************
** Meta object code from reading C++ file 'MangaDexSource.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.12.8)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../../src/MangaDexSource.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'MangaDexSource.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.12.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
struct qt_meta_stringdata_MangaDexSource_t {
    QByteArrayData data[21];
    char stringdata0[228];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_MangaDexSource_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_MangaDexSource_t qt_meta_stringdata_MangaDexSource = {
    {
QT_MOC_LITERAL(0, 0, 14), // "MangaDexSource"
QT_MOC_LITERAL(1, 15, 14), // "mangaListReady"
QT_MOC_LITERAL(2, 30, 0), // ""
QT_MOC_LITERAL(3, 31, 6), // "mangas"
QT_MOC_LITERAL(4, 38, 16), // "mangaDetailReady"
QT_MOC_LITERAL(5, 55, 5), // "manga"
QT_MOC_LITERAL(6, 61, 16), // "chapterListReady"
QT_MOC_LITERAL(7, 78, 8), // "chapters"
QT_MOC_LITERAL(8, 87, 13), // "pageListReady"
QT_MOC_LITERAL(9, 101, 5), // "pages"
QT_MOC_LITERAL(10, 107, 12), // "networkError"
QT_MOC_LITERAL(11, 120, 7), // "message"
QT_MOC_LITERAL(12, 128, 15), // "getPopularManga"
QT_MOC_LITERAL(13, 144, 4), // "page"
QT_MOC_LITERAL(14, 149, 11), // "searchManga"
QT_MOC_LITERAL(15, 161, 5), // "query"
QT_MOC_LITERAL(16, 167, 15), // "getMangaDetails"
QT_MOC_LITERAL(17, 183, 7), // "mangaId"
QT_MOC_LITERAL(18, 191, 14), // "getChapterList"
QT_MOC_LITERAL(19, 206, 11), // "getPageList"
QT_MOC_LITERAL(20, 218, 9) // "chapterId"

    },
    "MangaDexSource\0mangaListReady\0\0mangas\0"
    "mangaDetailReady\0manga\0chapterListReady\0"
    "chapters\0pageListReady\0pages\0networkError\0"
    "message\0getPopularManga\0page\0searchManga\0"
    "query\0getMangaDetails\0mangaId\0"
    "getChapterList\0getPageList\0chapterId"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_MangaDexSource[] = {

 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
      12,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       5,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    1,   74,    2, 0x06 /* Public */,
       4,    1,   77,    2, 0x06 /* Public */,
       6,    1,   80,    2, 0x06 /* Public */,
       8,    1,   83,    2, 0x06 /* Public */,
      10,    1,   86,    2, 0x06 /* Public */,

 // methods: name, argc, parameters, tag, flags
      12,    1,   89,    2, 0x02 /* Public */,
      12,    0,   92,    2, 0x22 /* Public | MethodCloned */,
      14,    2,   93,    2, 0x02 /* Public */,
      14,    1,   98,    2, 0x22 /* Public | MethodCloned */,
      16,    1,  101,    2, 0x02 /* Public */,
      18,    1,  104,    2, 0x02 /* Public */,
      19,    1,  107,    2, 0x02 /* Public */,

 // signals: parameters
    QMetaType::Void, QMetaType::QVariantList,    3,
    QMetaType::Void, QMetaType::QVariantMap,    5,
    QMetaType::Void, QMetaType::QVariantList,    7,
    QMetaType::Void, QMetaType::QVariantList,    9,
    QMetaType::Void, QMetaType::QString,   11,

 // methods: parameters
    QMetaType::Void, QMetaType::Int,   13,
    QMetaType::Void,
    QMetaType::Void, QMetaType::QString, QMetaType::Int,   15,   13,
    QMetaType::Void, QMetaType::QString,   15,
    QMetaType::Void, QMetaType::QString,   17,
    QMetaType::Void, QMetaType::QString,   17,
    QMetaType::Void, QMetaType::QString,   20,

       0        // eod
};

void MangaDexSource::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<MangaDexSource *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->mangaListReady((*reinterpret_cast< QVariantList(*)>(_a[1]))); break;
        case 1: _t->mangaDetailReady((*reinterpret_cast< QVariantMap(*)>(_a[1]))); break;
        case 2: _t->chapterListReady((*reinterpret_cast< QVariantList(*)>(_a[1]))); break;
        case 3: _t->pageListReady((*reinterpret_cast< QVariantList(*)>(_a[1]))); break;
        case 4: _t->networkError((*reinterpret_cast< QString(*)>(_a[1]))); break;
        case 5: _t->getPopularManga((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 6: _t->getPopularManga(); break;
        case 7: _t->searchManga((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< int(*)>(_a[2]))); break;
        case 8: _t->searchManga((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 9: _t->getMangaDetails((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 10: _t->getChapterList((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 11: _t->getPageList((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (MangaDexSource::*)(QVariantList );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MangaDexSource::mangaListReady)) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (MangaDexSource::*)(QVariantMap );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MangaDexSource::mangaDetailReady)) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (MangaDexSource::*)(QVariantList );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MangaDexSource::chapterListReady)) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (MangaDexSource::*)(QVariantList );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MangaDexSource::pageListReady)) {
                *result = 3;
                return;
            }
        }
        {
            using _t = void (MangaDexSource::*)(QString );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MangaDexSource::networkError)) {
                *result = 4;
                return;
            }
        }
    }
}

QT_INIT_METAOBJECT const QMetaObject MangaDexSource::staticMetaObject = { {
    &QObject::staticMetaObject,
    qt_meta_stringdata_MangaDexSource.data,
    qt_meta_data_MangaDexSource,
    qt_static_metacall,
    nullptr,
    nullptr
} };


const QMetaObject *MangaDexSource::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *MangaDexSource::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_MangaDexSource.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int MangaDexSource::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 12)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 12;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 12)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 12;
    }
    return _id;
}

// SIGNAL 0
void MangaDexSource::mangaListReady(QVariantList _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void MangaDexSource::mangaDetailReady(QVariantMap _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void MangaDexSource::chapterListReady(QVariantList _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void MangaDexSource::pageListReady(QVariantList _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}

// SIGNAL 4
void MangaDexSource::networkError(QString _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 4, _a);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
