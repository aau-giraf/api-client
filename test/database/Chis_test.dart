import 'dart:io';
import 'package:api_client/models/activity_model.dart';
import 'package:api_client/models/enums/activity_state_enum.dart';
import 'package:api_client/models/enums/role_enum.dart';
import 'package:api_client/models/enums/weekday_enum.dart';
import 'package:api_client/models/giraf_user_model.dart';
import 'package:api_client/models/pictogram_model.dart';
import 'package:api_client/offline_database/offline_db_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockOfflineDbHandler extends OfflineDbHandler {
  MockOfflineDbHandler._() : super();

  static final MockOfflineDbHandler instance = MockOfflineDbHandler._();
  @override
  Future<Database> initializeDatabase() async {
    sqfliteFfiInit();
    final Database db = await databaseFactoryFfi.openDatabase(
        join(Directory.current.path, 'test', 'database', 'girafTest.db'),
        options: OpenDatabaseOptions(version: 1));
    createTables(db);
    return db;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test('Try to create the test db', () async {
    expect(await MockOfflineDbHandler.instance.getCurrentDBVersion(), 1);
    // We might need this if somthing is wrong
    // in the tests and it doesn't close itself
    //testDb.closeDb();
  });
  test('Register an account in the offline db', () async {
    final OfflineDbHandler dbHandler = MockOfflineDbHandler.instance;
    //create fake account
    const String testUsername = 'BobJensen123';
    final GirafUserModel fakeAccount = GirafUserModel(
        role: Role.Citizen,
        username: testUsername,
        displayName: 'Bob Jensen',
        department: 1);
    final Map<String, dynamic> body = <String, dynamic>{
      'username': fakeAccount.username,
      'displayName': fakeAccount.displayName,
      'password': 'TestPassword123',
      'departmentId': fakeAccount.department,
      'role': fakeAccount.role.toString().split('.').last,
    };
    final GirafUserModel fakeUserRes = await dbHandler.registerAccount(body);
    expect(fakeUserRes.username, testUsername);
    expect(fakeUserRes.role, Role.Citizen);
  });
  test('Test if it is possible to register the same account twice', () async {
    final OfflineDbHandler dbHandler = MockOfflineDbHandler.instance;
    try {
      //create fake account
      const String testUsername = 'BobJensen123';
      final GirafUserModel fakeAccount = GirafUserModel(
          role: Role.Citizen,
          username: testUsername,
          displayName: 'Bob Jensen',
          department: 1);
      final Map<String, dynamic> body = <String, dynamic>{
        'username': fakeAccount.username,
        'displayName': fakeAccount.displayName,
        'password': 'TestPassword123',
        'departmentId': fakeAccount.department,
        'role': fakeAccount.role.toString().split('.').last,
      };
      expect(() => dbHandler.registerAccount(body),
          throwsA(isInstanceOf<Exception>()));
      await cleanUsers(dbHandler);
    } finally {
      await cleanUsers(dbHandler);
    }
  });
test('Add activity test', () async {
    //arrange
    final OfflineDbHandler dbHandler = MockOfflineDbHandler.instance;
    // final List<PictogramModel> fakePictograms = <PictogramModel>[];
    // final ActivityModel fakeActivity = ActivityModel(
    //     pictograms: fakePictograms,
    //     order: 1,
    //     id: 1,
    //     state: ActivityState.Normal,
    //     isChoiceBoard: true);
    //create fake account
    const String testUsername = 'BobJensen123';
    final GirafUserModel fakeAccount = GirafUserModel(
        role: Role.Citizen,
        username: testUsername,
        displayName: 'Bob Jensen',
        department: 1);
    final Map<String, dynamic> body = <String, dynamic>{
      'username': fakeAccount.username,
      'displayName': fakeAccount.displayName,
      'password': 'TestPassword123',
      'departmentId': fakeAccount.department,
      'role': fakeAccount.role.toString().split('.').last,
    };
    final GirafUserModel fakeUserRes = await dbHandler.registerAccount(body);
    //final Weekday fakeDay = Weekday(;
    //act
    // final ActivityModel fakeactivityModel = await dbHandler.addActivity(
    //     fakeActivity, '1', 'weekplanName', 2020, 50, Weekday.Friday);
    //assert
    expect(fakeUserRes.username, testUsername);
  });
  test('Perform a correct login attempt', () async {
    final MockOfflineDbHandler testdb = MockOfflineDbHandler.instance;
    const String testPassword = 'MyPassword32';
    final GirafUserModel testAcc = GirafUserModel(
        role: Role.Citizen,
        username: 'TestTest',
        displayName: 'Test Testersen',
        department: 1);
    final Map<String, dynamic> dbUser = <String, dynamic>{
      'username': testAcc.username,
      'displayName': testAcc.displayName,
      'password': testPassword,
      'departmentId': testAcc.department,
      'role': testAcc.role.toString().split('.').last,
    };
    await testdb.registerAccount(dbUser);
    final bool testLogin = await testdb.login(testAcc.username, testPassword);
    expect(testLogin, true);
    await cleanUsers(testdb);
  });

  test('Perform a correct login attempt 2', () async {
    final MockOfflineDbHandler testdb = MockOfflineDbHandler.instance;
    const String testPassword = 'hunter2';
    final GirafUserModel testAcc = GirafUserModel(
        role: Role.Citizen,
        username: 'PJacobsen',
        displayName: 'Peter Jacobsen',
        department: 2);
    final Map<String, dynamic> dbUser = <String, dynamic>{
      'username': testAcc.username,
      'displayName': testAcc.displayName,
      'password': testPassword,
      'departmentId': testAcc.department,
      'role': testAcc.role.toString().split('.').last,
    };
    await testdb.registerAccount(dbUser);
    final bool testLogin = await testdb.login(testAcc.username, testPassword);
    expect(testLogin, true);
    await cleanUsers(testdb);
  });

  test('Perform a wrong login attempt', () async {
    final MockOfflineDbHandler testdb = MockOfflineDbHandler.instance;
    const String testPassword = 'MyPassword32';
    const String wrongPassword = 'PasswordGuess128';
    final GirafUserModel testAcc = GirafUserModel(
        role: Role.Citizen,
        username: 'TestTest',
        displayName: 'Test Testersen',
        department: 1);
    final Map<String, dynamic> dbUser = <String, dynamic>{
      'username': testAcc.username,
      'displayName': testAcc.displayName,
      'password': testPassword,
      'departmentId': testAcc.department,
      'role': testAcc.role.toString().split('.').last,
    };
    await testdb.registerAccount(dbUser);
    final bool testLogin = await testdb.login(testAcc.username, wrongPassword);
    expect(testLogin, false);
    await cleanUsers(testdb);
  });

  test('Perform a wrong login attempt 2', () async {
    final MockOfflineDbHandler testdb = MockOfflineDbHandler.instance;
    const String testPassword = 'hejmeddig123';
    const String wrongPassword = 'Hejmeddig123';
    final GirafUserModel testAcc = GirafUserModel(
        role: Role.Citizen,
        username: 'SimOestGaard',
        displayName: 'Simon Østergård',
        department: 2);
    final Map<String, dynamic> dbUser = <String, dynamic>{
      'username': testAcc.username,
      'displayName': testAcc.displayName,
      'password': testPassword,
      'departmentId': testAcc.department,
      'role': testAcc.role.toString().split('.').last,
    };
    await testdb.registerAccount(dbUser);
    final bool testLogin = await testdb.login(testAcc.username, wrongPassword);
    expect(testLogin, false);
    await cleanUsers(testdb);
  });
  test('performs a successfull change of password ', () async {
    final OfflineDbHandler dbHandler = MockOfflineDbHandler.instance;
    const String testUsername = 'ChrisAaen11';
    final GirafUserModel changepassword = GirafUserModel(
      role: Role.Citizen,
      username: testUsername,
      displayName: 'Chris Aaen',
      department: 1);
        final Map<String, dynamic> body = <String, dynamic>{
      'username': changepassword.username,
      'displayName': changepassword.displayName,
      'password': 'TestPassword123',
      'departmentId': changepassword.department,
      'role': changepassword.role.toString().split('.').last,
  };
  final GirafUserModel fakeUserRes = await dbHandler.registerAccount(body);
 await dbHandler.changePassword(fakeUserRes.id, 'TestPassword444');
 final bool res = await dbHandler.login('ChrisAaen11', 'TestPassword444');
 expect(res, true);
await cleanUsers(dbHandler);
});

  test('performs a falied change of password ', () async {
    final OfflineDbHandler dbHandler = MockOfflineDbHandler.instance;
    const String testUsername = 'BrianJohnson44';
    final GirafUserModel changepassword = GirafUserModel(
      role: Role.Citizen,
      username: testUsername,
      displayName: 'Brian Johnson',
      department: 1);
        final Map<String, dynamic> body = <String, dynamic>{
      'username': changepassword.username,
      'displayName': changepassword.displayName,
      'password': 'TestPassword123',
      'departmentId': changepassword.department,
      'role': changepassword.role.toString().split('.').last,
  };
  final GirafUserModel fakeUserRes = await dbHandler.registerAccount(body);
 await dbHandler.changePassword(fakeUserRes.id, 'TestPassword444');
 final bool res = await dbHandler.login('ChrisAaen11', 'TestPassword6969');
 expect(res, false);
 await cleanUsers(dbHandler);
});

test('performs an update to activities', () {
  
});
}



Future<void> cleanUsers(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.rawDelete('DELETE FROM `Users`');
}

Future<void> cleanSettings(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `Setting`');
}

Future<void> cleanGaurdianRelations(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `GuardianRelations`');
}

Future<void> cleaWeekTemplates(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `WeekTemplates`');
}

Future<void> cleanWeek(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `Weeks`');
}

Future<void> cleanWeekdays(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `Weekdays`');
}

Future<void> cleanPictograms(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `Pictograms`');
}

Future<void> cleanActivities(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `Activities`');
}

Future<void> cleanPictogramRelations(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `PictogramRelations`');
}

Future<void> cleanTimers(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `Timers`');
}

Future<void> cleanFailedOnlineTransactions(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `FailedOnlineTransactions`');
}

Future<void> cleanWeekDayColors(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  db.rawDelete('DELETE * FROM `WeekDayColors`');
}