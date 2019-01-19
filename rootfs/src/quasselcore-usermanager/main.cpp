
#include <cstdlib>
#include <iostream>
#include <getopt.h>
#include <sstream>
#include <string>
#include <random>
#include <vector>

#include <QString>
/*
#include <QSettings>
#include <QByteArray>
#include <QVariant>
#include <QVariantMap>
#include <QJsonDocument>
#include <QJsonObject>
*/
#include <QFile>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QSqlError>
#include <QtCrypto>
#include <QCryptographicHash>

#include <QDebug>

#include <QuasselUser.h>


const char *progname = "quasselcore-usermanager";
const char *version = "1.0.1";
const char *copyright = "2019";
const char *email = "Bodo Schulz <bodo@boone-schulz.de>";

void print_help (void);
void print_usage (void);
QString hashPasswordSha2_512(const QString& password);
QString sha2_512(const QString& input);

// ------------------------------------------------------------------------------------------------

int main(int argc, char *argv[]) {

  QString database_file = "";
  QString quassel_user = "";
  QString quassel_password = "";

  int opt = 0;
  const char* const short_opts = "hVu:p:f:";
  const option long_opts[] = {
    {"help"    , no_argument      , nullptr, 'h'},
    {"version" , no_argument      , nullptr, 'V'},
    {"user"    , required_argument, nullptr, 'u'},
    {"password", required_argument, nullptr, 'p'},
    {"file"    , required_argument, nullptr, 'f'},
    {nullptr   , 0, nullptr, 0}
  };

  if(argc < 2)
    return 1;

  int long_index =0;
  while((opt = getopt_long(argc, argv, short_opts, long_opts, &long_index)) != -1) {

    switch(opt) {
      case 'h':
        print_help();
        return 0;
      case 'V':
        std::cout << progname << " v" << version << std::endl;
        return 0;
      case 'f':
        database_file = optarg;
        break;
      case 'u':
        quassel_user = optarg;
        break;
      case 'p':
        quassel_password = optarg;
        break;
      default:
        print_usage();
        return 1;
    }
  }

  /**
   * validate it
   */
  if(database_file.isEmpty()) {
    print_usage();
    std::cerr
      << "we need an database file.\n"
      << std::endl;
    return 1;
  }

  if( QFile(database_file).exists() == false ) {
    print_usage();
    std::cerr
      << "The database file " << database_file.toStdString() << " does not exist.\n"
      << std::endl;
    return 1;
  }

  /**
   *
   */



  QuasselUser qu(database_file);// = new QuasselUser();

  qDebug() << "sqlite is available : " << qu.isAvailable();
  qDebug() << "get user id: " << qu.getUserId("dodger");

  qDebug() << "add user id: " << qu.addUser("foo", "bar");

  qDebug() << "update user: " << qu.updateUser("foo", "barbar");

  qDebug() << "validate user: " << qu.validateUser("foo", "barbar2");

  qDebug() << qu.getUserAuthenticator(1);

/*
  QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");

  db.setDatabaseName(database_file);

  if(db.open() == false) {
    qDebug() << db.lastError().text();

    return 1;
  }


  QSqlQuery query;
  query.exec("SELECT * FROM quasseluser");

  while (query.next()) {
    QString name = query.value("username").toString();
    QString password = query.value("password").toString();
    qDebug() << name;
    qDebug() << password;
  }


  QString db_username = ""; //query.record().indexOf("username");

  while (query.next()) {
    QString name = query.value(db_username).toString();
    qDebug() << name;
  }

  qDebug() << hashPasswordSha2_512("7naiy6is");
*/

/*
  //query.bindValue(":name", name);
  if(query.exec()) {
    success = true;

  } else {
    qDebug() << query.lastError();
  }



  QCA::init();
  if(!QCA::isSupported("sha1"))
    qDebug("SHA-1 not supported!");
*/


/*
  QSettings settings( database_file,  QSettings::IniFormat );

  if(dump_database_file) {

    //
    //  dump configuration
    //

    QVariant authSettings = settings.value("Core/AuthSettings");
    QJsonObject authJson = authSettings.toJsonObject();
    QVariant storageSettings = settings.value("Core/StorageSettings");
    QJsonObject storageJson = storageSettings.toJsonObject();

    QJsonDocument doc;
    doc.setObject(authJson);
    QString authStrJson( doc.toJson(QJsonDocument::Compact) );

    doc.setObject(storageJson);
    QString storageStrJson( doc.toJson(QJsonDocument::Compact) );

    std::cout
      << std::endl
      << "config file : " << database_file.toStdString()
      << std::endl
      << std::endl
      << "config version: " << settings.value("Config/Version").toUInt()
      << std::endl
      << "Core AuthSettings: " << authStrJson.toStdString()
      << std::endl
      << "Core StorageSettings: " << storageStrJson.toStdString()
      << std::endl
      << std::endl;

    return 0;
  }

  bool ldpa_config_valid = true;
  QByteArray config_dir         = qgetenv("QUASSEL_CONFIG_DIR");
  QByteArray ldap_base_dn       = qgetenv("LDAP_BASE_DN");
  QByteArray ldap_bind_dn       = qgetenv("LDAP_BIND_DN");
  QByteArray ldap_bind_password = qgetenv("LDAP_BIND_PASSWORD");
  QByteArray ldap_filter        = qgetenv("LDAP_FILTER");
  QByteArray ldap_hostname      = qgetenv("LDAP_HOSTNAME");
  QByteArray ldap_port          = qgetenv("LDAP_PORT");
  QByteArray ldap_uid_attribute = qgetenv("LDAP_UID_ATTR");

  std::ostringstream ss;

  // set Config Version
  if( settings.value("Config/Version").toUInt() == 0 )
    settings.setValue("Config/Version", 1);

  // ----------------

  if(ldap_bind_dn.isEmpty()) {
    ldpa_config_valid = false;
    ss
      << " - LDAP_BASE_DN missing"
      << std::endl;
  }

  if(ldap_bind_password.isEmpty()) {
    ldpa_config_valid = false;
    ss
      << " - LDAP_BIND_PASSWORD missing"
      << std::endl;
  }

  if(ldap_filter.isEmpty()) {
    ldpa_config_valid = false;
    ss
      << " - LDAP_FILTER missing"
      << std::endl;
  }

  if(ldap_hostname.isEmpty()) {
    ldpa_config_valid = false;
    ss
      << " - LDAP_HOSTNAME missing"
      << std::endl;
  }

  if(ldap_port.isEmpty()) {
    ldpa_config_valid = false;
    ss
      << " - LDAP_PORT missing"
      << std::endl;
  }

  if(ldap_uid_attribute.isEmpty()) {
    ldpa_config_valid = false;
    ss
      << " - LDAP_UID_ATTR missing"
      << std::endl;
  }

  if( ldpa_config_valid == false ) {

    std::cout
      << std::endl
      << "WARNING:"
      << std::endl
      << "The LDAP configuration was not written because not all required environment variables were set."
      << std::endl
      << ss.str()
      << std::endl;

    return 0;
  }

  QVariantMap map;
  QVariantMap map2;

  map2.insert("BaseDN"       , ldap_base_dn);
  map2.insert("BindDN"       , ldap_bind_dn);
  map2.insert("BindPassword" , ldap_bind_password);
  map2.insert("Filter"       , ldap_filter);
  map2.insert("Hostname"     , ldap_hostname);
  map2.insert("Port"         , ldap_port);
  map2.insert("UidAttribute" , ldap_uid_attribute);

  map.insert("Authenticator", "LDAP");
  map.insert("AuthProperties", map2);

  QJsonObject json = QJsonObject::fromVariantMap(map);
  settings.setValue("Core/AuthSettings", json.toVariantMap());
*/

  return 0;
}


/**
 *  from https://github.com/quassel/quassel/blob/812b7b9f9d4cbd413294849624e7af7e5394f388/src/core/storage.cpp
 */

QString hashPasswordSha2_512(const QString& password) {

    // Generate a salt of 512 bits (64 bytes) using the Mersenne Twister
    std::random_device seed;
    std::mt19937 generator(seed());
    std::uniform_int_distribution<int> distribution(0, 255);
    QByteArray saltBytes;
    saltBytes.resize(64);
    for (int i = 0; i < 64; i++) {
        saltBytes[i] = (unsigned char)distribution(generator);
    }
    QString salt(saltBytes.toHex());

    // Append the salt to the password, hash the result, and append the salt value
    return sha2_512(password + salt) + ":" + salt;
}


QString sha2_512(const QString& input) {
  return QString(QCryptographicHash::hash(input.toUtf8(), QCryptographicHash::Sha512).toHex());
}

/**
 *
 */
void print_help (void) {

  std::cout
    << std::endl
    << progname << " v" << version << std::endl
    << "  Copyright (c) " << copyright << " " << email << std::endl
    << std::endl
    << "write an quassel core config file" << std::endl
    << "read following environment variablen to  write an Ldap configuration:" << std::endl
    << "  - LDAP_BASE_DN, " << std::endl
    << "  - LDAP_BIND_DN " << std::endl
    << "  - LDAP_BIND_PASSWORD" << std::endl
    << "  - LDAP_FILTER, " << std::endl
    << "  - LDAP_HOSTNAME " << std::endl
    << "  - LDAP_PORT" << std::endl
    << "  - LDAP_UID_ATTR" << std::endl;

  print_usage();

  std::cout
    << "Options:" << std::endl
    << " -h, --help" << std::endl
    << "    Print detailed help screen" << std::endl
    << " -V, --version" << std::endl
    << "    Print version information" << std::endl
    << " -f, --file" << std::endl
    << "    config file." << std::endl
    << " -d, --dump" << std::endl
    << "    dump content config file" << std::endl;
}

/**
 *
 */
void print_usage (void) {
  std::cout << std::endl;
  std::cout << "Usage:" << std::endl;
  std::cout << " " << progname << " [-file <config file>] --dump"  << std::endl;
  std::cout << std::endl;
}
