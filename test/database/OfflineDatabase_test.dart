import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:api_client/models/settings_model.dart';
import 'package:api_client/models/activity_model.dart';
import 'package:api_client/models/displayname_model.dart';
import 'package:api_client/models/enums/access_level_enum.dart';
import 'package:api_client/models/enums/activity_state_enum.dart';
import 'package:api_client/models/enums/role_enum.dart';
import 'package:api_client/models/enums/weekday_enum.dart';
import 'package:api_client/models/giraf_user_model.dart';
import 'package:api_client/models/pictogram_model.dart';
import 'package:api_client/models/timer_model.dart';
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
    final String tempDir = Directory.current.path;
    String dbDir;
    Database db;
    if (tempDir.split(separator).last == 'test') {
      dbDir = join(tempDir, 'database');
    } else {
      dbDir = join(tempDir, 'test', 'database');
    }
    db = await databaseFactoryFfi.openDatabase(join(dbDir, 'girafTest.db'),
        options: OpenDatabaseOptions(version: 1));
    createTables(db);
    return db;
  }

  @override
  Future<String> get getPictogramDirectory async {
    final String tempDir = Directory.current.path;
    Directory imageDirectory;
    if (tempDir.split(separator).last == 'test') {
      imageDirectory = Directory(join(tempDir, 'pictograms'));
    } else {
      imageDirectory = Directory(join(tempDir, 'test', 'pictograms'));
    }
    imageDirectory.createSync(recursive: true);
    return imageDirectory.path;
  }
}

//Test GirafUserModel 1
final GirafUserModel jamesbondTestUser = GirafUserModel(
    username: 'JamesBond007',
    department: 1,
    displayName: 'James Bond',
    roleName: 'Citizen',
    id: 'james007bond',
    role: Role.Citizen,
    offlineId: 1);
// Test account body 1
final Map<String, dynamic> jamesBody = <String, dynamic>{
  'username': jamesbondTestUser.username,
  'displayName': jamesbondTestUser.displayName,
  'password': 'TestPassword123',
  'department': jamesbondTestUser.department,
  'role': jamesbondTestUser.role.toString().split('.').last
};
//Test GirafUserModel 2
final GirafUserModel edTestUser = GirafUserModel(
    department: 34,
    offlineId: 34,
    role: Role.Citizen,
    id: 'edmcniel01',
    roleName: 'Citizen',
    displayName: 'Ed McNiel',
    username: 'EdMcNiel34');
//Test account body 2
final Map<String, dynamic> edBody = <String, dynamic>{
  'username': edTestUser.username,
  'displayName': edTestUser.displayName,
  'password': 'MyPassword42',
  'department': edTestUser.department,
  'role': edTestUser.role.toString().split('.').last
};
//Test Pictogram 1
final PictogramModel scrum = PictogramModel(
    accessLevel: AccessLevel.PUBLIC,
    id: 44,
    title: 'Picture of Scrum',
    lastEdit: DateTime.now(),
    userId: '1');

//Test Pictogram 2
final PictogramModel extreme = PictogramModel(
    accessLevel: AccessLevel.PROTECTED,
    id: 20,
    title: 'Picture of XP',
    lastEdit: DateTime.now(),
    userId: '3');

//Lists of test pictograms
List<PictogramModel> testListe = <PictogramModel>[scrum];
List<PictogramModel> testListe2 = <PictogramModel>[extreme];

//Test ActivityModel 1
final ActivityModel lege = ActivityModel(
  id: 69,
  isChoiceBoard: true,
  order: 1,
  pictograms: testListe,
  choiceBoardName: 'Testchoice',
  state: ActivityState.Active,
  timer: null,
);

//Test ActivityModel 2
final ActivityModel spise = ActivityModel(
  id: 70,
  pictograms: testListe2,
  order: 2,
  state: ActivityState.Active,
  isChoiceBoard: true,
  choiceBoardName: 'Testsecondchoice',
  timer: null,
);

//Test Timer
final TimerModel timer = TimerModel(
  startTime: DateTime.now(),
  progress: 1,
  fullLength: 10,
  paused: false,
  key: 44,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final MockOfflineDbHandler dbHandler = MockOfflineDbHandler.instance;
  test('Try to create the test db', () async {
    expect(await dbHandler.getCurrentDBVersion(), 1);
    // We might need this if somthing is wrong
    // in the tests and it doesn't close itself
    //dbHandler.closeDb();
  });
  test('Register an account in the offline db', () async {
    //create fake account
    try {
      final GirafUserModel fakeUserRes =
          await dbHandler.registerAccount(jamesBody);
      expect(fakeUserRes.username, jamesbondTestUser.username);
      expect(fakeUserRes.displayName, jamesbondTestUser.displayName);
      expect(fakeUserRes.role, Role.Citizen);
      await cleanUsers(dbHandler);
    } finally {
      await cleanUsers(dbHandler);
    }
  });
  test('Test if it is possible to register the same account twice', () async {
    try {
      //create fake account
      await dbHandler.registerAccount(jamesBody);
      expect(() => dbHandler.registerAccount(jamesBody),
          throwsA(isInstanceOf<Exception>()));
      await killAll(dbHandler);
    } finally {
      await killAll(dbHandler);
    }
  });

  test('Find a user ID through their username', () async {
    try {
      final GirafUserModel jamesUser =
          await dbHandler.registerAccount(jamesBody);

      final String idReturn = await dbHandler.getUserId(jamesUser.username);
      expect(idReturn, jamesUser.id);
    } finally {
      await cleanUsers(dbHandler);
    }
  });
  test('Add activity test', () async {
    try {
      //arrange
      //add pictograms to offline database
      final PictogramModel fakePicto1 = await dbHandler.createPictogram(scrum);
      final PictogramModel fakePicto2 =
          await dbHandler.createPictogram(extreme);
      //act
      lege.pictograms = <PictogramModel>[fakePicto1, fakePicto2];
      final ActivityModel fakeactivityModel = await dbHandler.addActivity(
          lege, '1', 'weekplanName', 2020, 50, Weekday.Friday);
      //assert
      expect(lege.id, fakeactivityModel.id);
      expect(lege.state, fakeactivityModel.state);
    } finally {
      await killAll(dbHandler);
    }
  });
  test('Add activity test with timer', () async {
    try {
      //arrange
      //add pictograms to offline database
      final PictogramModel fakePicto1 = await dbHandler.createPictogram(scrum);
      final PictogramModel fakePicto2 =
          await dbHandler.createPictogram(extreme);
      //act
      lege.pictograms = <PictogramModel>[fakePicto1, fakePicto2];
      lege.timer = timer;
      final ActivityModel fakeactivityModel = await dbHandler.addActivity(
          lege, '1', 'weekplanName', 2020, 50, Weekday.Friday);

      //assert
      expect(lege.id, fakeactivityModel.id);
      expect(lege.state, fakeactivityModel.state);
      expect(lege.timer.key, fakeactivityModel.timer.key);
    } finally {
      await killAll(dbHandler);
    }
  });
  test('Perform a correct login attempt', () async {
    try {
      // The correct Password for the jamesBody user is 'TestPassword123'
      const String passAttempt = 'TestPassword123';
      await dbHandler.registerAccount(jamesBody);
      final bool testLogin =
          await dbHandler.login(jamesbondTestUser.username, passAttempt);
      expect(testLogin, true);
    } finally {
      await cleanUsers(dbHandler);
    }
  });

  test('Perform a correct login attempt 2', () async {
    try {
      const String testUsername = 'JacobPed';
      const String testPassword = 'hunter2';
      final Map<String, dynamic> dbUser = <String, dynamic>{
        'username': testUsername,
        'displayName': 'Jacob Pedersen',
        'password': testPassword,
        'departmentId': 1,
        'role': 'Citizen',
      };
      await dbHandler.registerAccount(dbUser);
      final bool testLogin = await dbHandler.login(testUsername, testPassword);
      expect(testLogin, true);
    } finally {
      await cleanUsers(dbHandler);
    }
  });

  test('Perform a incorrect login attempt', () async {
    try {
      // The correct Password for the jamesBody user is 'TestPassword123'
      const String passAttempt = 'GoldenGun';
      await dbHandler.registerAccount(jamesBody);
      final bool testLogin =
          await dbHandler.login(jamesbondTestUser.username, passAttempt);
      expect(testLogin, false);
    } finally {
      await cleanUsers(dbHandler);
    }
  });

  test('Perform a incorrect login attempt 2', () async {
    try {
      const String testUsername = 'SErikson';
      const String testPassword = 'hejmeddig123';
      const String passAttempt = 'Hejmeddig123';
      final Map<String, dynamic> dbUser = <String, dynamic>{
        'username': testUsername,
        'displayName': 'Simon Erikson',
        'password': testPassword,
        'departmentId': 1,
        'role': 'Guardian',
      };
      await dbHandler.registerAccount(dbUser);
      final bool testLogin = await dbHandler.login(testUsername, passAttempt);
      expect(testLogin, false);
    } finally {
      await cleanUsers(dbHandler);
    }
  });

  test('Update a user with a new attribute', () async {
    try {
      final GirafUserModel formerUser =
          await dbHandler.registerAccount(jamesBody);
      expect(formerUser.username, jamesbondTestUser.username);
      final GirafUserModel updatedUser = formerUser;
      updatedUser.username = 'DoubleOhSeven';
      final GirafUserModel newUser = await dbHandler.updateUser(updatedUser);
      expect(newUser.id, formerUser.id);
      expect(newUser.username, updatedUser.username);
    } finally {
      await killAll(dbHandler);
    }
  });
  test('Create a pictogram in the offline database', () async {
    try {
      await dbHandler.createPictogram(scrum);
      final PictogramModel dbPicto = await dbHandler.getPictogramID(scrum.id);
      expect(dbPicto.id, scrum.id);
    } finally {
      await killAll(dbHandler);
    }
  });

  test('Update existing pictogram in database', () async {
    try {
      await dbHandler.createPictogram(scrum);
      final PictogramModel scrum2 = scrum;
      scrum2.title = 'Super Scrum';
      final PictogramModel updatedPicto =
          await dbHandler.updatePictogram(scrum2);

      expect(updatedPicto.id, scrum2.id);
      expect(updatedPicto.title, scrum2.title);
    } finally {
      await killAll(dbHandler);
    }
  });

  test('Delete a pictogram from database', () async {
    try {
      final PictogramModel dbPicto = await dbHandler.createPictogram(scrum);
      expect(dbPicto.id, scrum.id);
      final bool wasDeleted = await dbHandler.deletePictogram(dbPicto.id);
      expect(wasDeleted, true);
    } finally {
      await killAll(dbHandler);
    }
  });

  test('Update the image contained in a pictogram', () async {
    try {
      final String tempDir = Directory.current.path;
      Directory pictoDir;
      Directory newPictoDir;
      if (tempDir.split(separator).last == 'test') {
        pictoDir = Directory(join(tempDir, 'pictograms', 'giraf.png'));
      } else {
        pictoDir = Directory(join(tempDir, 'test', 'pictograms', 'giraf.png'));
      }
      final File pictoPath = File(pictoDir.path);
      final Uint8List pictoUInt8 = await pictoPath.readAsBytes();
      await dbHandler.createPictogram(scrum);
      await dbHandler.updateImageInPictogram(scrum.id, pictoUInt8);
      if (tempDir.split(separator).last == 'test') {
        newPictoDir = Directory(join(tempDir, 'pictograms'));
      } else {
        newPictoDir = Directory(join(tempDir, 'test', 'pictograms'));
      }
      final File newSavedPicto =
          File(join(newPictoDir.path, '${scrum.id}.png'));
      final Uint8List newUInt8 = await newSavedPicto.readAsBytes();
      expect(newUInt8, pictoUInt8);
      newSavedPicto.delete();
    } finally {
      await killAll(dbHandler);
    }
  });

  test('performs a successful login after password change', () async {
    try {
      const String oldPass = 'TestPassword123';
      const String newPass = 'TestPassword444';

      final Map<String, dynamic> body = <String, dynamic>{
        'username': jamesbondTestUser.username,
        'displayName': jamesbondTestUser.displayName,
        'password': oldPass,
        'department': jamesbondTestUser.department,
        'role': jamesbondTestUser.role.toString().split('.').last,
      };
      final GirafUserModel fakeUserRes = await dbHandler.registerAccount(body);
      final bool loginOld =
          await dbHandler.login(fakeUserRes.username, oldPass);
      expect(loginOld, true);
      await dbHandler.changePassword(fakeUserRes.id, newPass);
      final bool loginNew =
          await dbHandler.login(fakeUserRes.username, newPass);
      expect(loginNew, true);
    } finally {
      await killAll(dbHandler);
    }
  });

  test('performs a failed login after password change', () async {
    try {
      const String newPass = 'testPassword444';
      const String oldPass = 'TestPassword123';
      final Map<String, dynamic> body = <String, dynamic>{
        'username': jamesbondTestUser.username,
        'displayName': jamesbondTestUser.displayName,
        'password': oldPass,
        'departmentId': jamesbondTestUser.department,
        'role': jamesbondTestUser.role.toString().split('.').last,
      };
      final GirafUserModel fakeUserRes = await dbHandler.registerAccount(body);
      bool sameLogin = await dbHandler.login(fakeUserRes.username, oldPass);
      expect(sameLogin, true);
      await dbHandler.changePassword(fakeUserRes.id, newPass);
      sameLogin = await dbHandler.login(fakeUserRes.username, oldPass);
      expect(sameLogin, false);
    } finally {
      await killAll(dbHandler);
    }
  });

  test('Performs a account deletion action', () async {
    try {
      final GirafUserModel edUser = await dbHandler.registerAccount(edBody);
      final bool delAction = await dbHandler.deleteAccount(edUser.id);
      expect(delAction, true);
    } finally {
      await cleanUsers(dbHandler);
    }
  });

  test('Attempt to delete an non-matching account', () async {
    final bool delAction = await dbHandler.deleteAccount('50');
    expect(delAction, false);
  });

  test('Get the list of citizens related to a guardian through ID', () async {
    try {
      final GirafUserModel newGuardian = GirafUserModel(
          role: Role.Guardian,
          username: 'Alex Jones',
          displayName: 'AJones',
          department: 1);

      final Map<String, dynamic> guardBody = <String, dynamic>{
        'username': newGuardian.username,
        'displayName': newGuardian.displayName,
        'password': 'pwd1234',
        'departmentId': newGuardian.department,
        'role': newGuardian.role.toString().split('.').last,
      };
      final GirafUserModel citizen1Res =
          await dbHandler.registerAccount(jamesBody);
      final GirafUserModel citizen2Res =
          await dbHandler.registerAccount(edBody);
      final GirafUserModel guardianRes =
          await dbHandler.registerAccount(guardBody);

      expect(citizen1Res.username, jamesbondTestUser.username);
      expect(citizen1Res.role, Role.Citizen);

      expect(citizen2Res.username, edTestUser.username);
      expect(citizen2Res.role, Role.Citizen);

      expect(guardianRes.username, newGuardian.username);
      expect(guardianRes.role, Role.Guardian);

      await dbHandler.addCitizenToGuardian(guardianRes.id, citizen1Res.id);
      await dbHandler.addCitizenToGuardian(guardianRes.id, citizen2Res.id);

      final DisplayNameModel cit1 = DisplayNameModel(
          id: citizen1Res.id,
          displayName: citizen1Res.displayName,
          role: citizen1Res.role.toString().split('.').last);

      final DisplayNameModel cit2 = DisplayNameModel(
          id: citizen2Res.id,
          displayName: citizen2Res.displayName,
          role: citizen2Res.role.toString().split('.').last);

      final List<DisplayNameModel> citizenList = <DisplayNameModel>[cit1, cit2];
      final List<DisplayNameModel> guardianList =
          await dbHandler.getCitizens(guardianRes.id);
      expect(guardianList[0].id, citizenList[0].id);
      expect(guardianList[1].id, citizenList[1].id);
      expect(guardianList[0].displayName, citizenList[0].displayName);
      expect(guardianList[1].displayName, citizenList[1].displayName);
      expect(guardianList[0].role, citizenList[0].role);
      expect(guardianList[1].role, citizenList[1].role);
    } finally {
      await killAll(dbHandler);
    }
  });
  test('Get the list of guardians related to a citizen through ID', () async {
    try {
      final GirafUserModel newGuardian = GirafUserModel(
          role: Role.Guardian,
          username: 'Alex Jones',
          displayName: 'AJones',
          department: 1);

      final Map<String, dynamic> guardBody = <String, dynamic>{
        'username': newGuardian.username,
        'displayName': newGuardian.displayName,
        'password': 'pwd1234',
        'departmentId': newGuardian.department,
        'role': newGuardian.role.toString().split('.').last,
      };
      final GirafUserModel newGuardian2 = GirafUserModel(
          role: Role.Guardian,
          username: 'Eminem',
          displayName: 'Em',
          department: 1);

      final Map<String, dynamic> guardBody2 = <String, dynamic>{
        'username': newGuardian2.username,
        'displayName': newGuardian2.displayName,
        'password': 'namedrop69',
        'departmentId': newGuardian2.department,
        'role': newGuardian2.role.toString().split('.').last,
      };
      final GirafUserModel citizen1Res =
          await dbHandler.registerAccount(jamesBody);
      final GirafUserModel guardian1Res =
          await dbHandler.registerAccount(guardBody);
      final GirafUserModel guardian2Res =
          await dbHandler.registerAccount(guardBody2);

      expect(citizen1Res.username, jamesbondTestUser.username);
      expect(citizen1Res.role, Role.Citizen);

      expect(guardian1Res.username, newGuardian.username);
      expect(guardian1Res.role, Role.Guardian);

      expect(guardian2Res.username, newGuardian2.username);
      expect(guardian2Res.role, Role.Guardian);

      await dbHandler.addCitizenToGuardian(guardian1Res.id, citizen1Res.id);
      await dbHandler.addCitizenToGuardian(guardian2Res.id, citizen1Res.id);

      final DisplayNameModel guard1 = DisplayNameModel(
          id: guardian1Res.id,
          displayName: guardian1Res.displayName,
          role: guardian1Res.role.toString().split('.').last);
      final DisplayNameModel guard2 = DisplayNameModel(
          id: guardian2Res.id,
          displayName: guardian2Res.displayName,
          role: guardian2Res.role.toString().split('.').last);

      final List<DisplayNameModel> guardianListexp = <DisplayNameModel>[
        guard1,
        guard2
      ];
      final List<DisplayNameModel> guardianList =
          await dbHandler.getGuardians(citizen1Res.id);
      expect(guardianList[0].id, guardianListexp[0].id);
      expect(guardianList[1].id, guardianListexp[1].id);
      expect(guardianList[0].displayName, guardianListexp[0].displayName);
      expect(guardianList[1].displayName, guardianListexp[1].displayName);
      expect(guardianList[0].role, guardianListexp[0].role);
      expect(guardianList[1].role, guardianListexp[1].role);
    } finally {
      await killAll(dbHandler);
    }
  });
  test('update an activity with timer is null', () async {
    try {
      final GirafUserModel jamesUser =
          await dbHandler.registerAccount(jamesBody);
      final PictogramModel fakePictogram =
          await dbHandler.createPictogram(scrum);
      lege.pictograms = <PictogramModel>[fakePictogram];
      final ActivityModel model = await dbHandler.addActivity(
          lege, jamesUser.id, 'weekplanName', 2020, 43, Weekday.Monday);
      expect(model.state, ActivityState.Active);
      model.state = ActivityState.Completed;
      final ActivityModel res =
          await dbHandler.updateActivity(model, jamesUser.id);
      expect(res.state, ActivityState.Completed);
    } finally {
      await killAll(dbHandler);
    }
  });

  test('update an activity with timer', () async {
    try {
      await dbHandler.registerAccount(jamesBody);
      final PictogramModel fakePictogram =
          await dbHandler.createPictogram(scrum);
      lege.pictograms = <PictogramModel>[fakePictogram];
      final ActivityModel model = await dbHandler.addActivity(
          lege, '33', 'weekplanName', 2020, 43, Weekday.Monday);
      model.order = 0;
      model.timer = timer;
      final ActivityModel res = await dbHandler.updateActivity(model, '33');
      expect(res.order, 0);
    } finally {
      await killAll(dbHandler);
    }
  });
  test('Get a user\'s settings', () async {
    try {
      final GirafUserModel body = await dbHandler.registerAccount(jamesBody);
      final SettingsModel res = await dbHandler.getUserSettings(body.id);
      expect(res, isNot(null));
    } finally {
      await killAll(dbHandler);
    }
  });

  test('Update a user\'s settings', () async {
    try {
      //test to be created
    } finally {
      await killAll(dbHandler);
    }
  });

  test('Delete an activity from weekplan', () async {
    try {
      final ActivityModel testActivity = lege;
      testActivity.pictograms = <PictogramModel>[scrum];
      testActivity.timer = timer;
      await dbHandler.registerAccount(jamesBody);
      final ActivityModel fakeActivity = await dbHandler.addActivity(
          lege, jamesbondTestUser.id, 'weekplanName', 2020, 43, Weekday.Friday);

      expect(fakeActivity.id, lege.id);
      final bool delResult =
          await dbHandler.deleteActivity(fakeActivity.id, jamesbondTestUser.id);
      expect(delResult, true);
    } finally {
      await killAll(dbHandler);
    }
  });

  test('Create and find a pictogram', () async {
    try {
      final PictogramModel tempPicto = scrum;
      final PictogramModel pictoTest =
          await dbHandler.createPictogram(tempPicto);
      final String tempDir = Directory.current.path;
      Directory pictoDir;
      if (tempDir.split(separator).last == 'test') {
        pictoDir = Directory(join(tempDir, 'pictograms'));
      } else {
        pictoDir = Directory(join(tempDir, 'test', 'pictograms'));
      }
      final File pictoPath = File(join(pictoDir.path, 'giraf.png'));
      final File newPictoPath =
          File(join(pictoDir.path, '${tempPicto.id}.png'));
      final Uint8List testImage = await pictoPath.readAsBytes();
      await dbHandler.updateImageInPictogram(pictoTest.id, testImage);
      final Image foundImage = await dbHandler.getPictogramImage(pictoTest.id);
      expect(foundImage.image, Image.file(newPictoPath).image);
      try {
        newPictoPath.delete();
      } on FileSystemException {
        //Exception can be thrown if there is no file to delete
        //if it was never created
      }
    } finally {
      await killAll(dbHandler);
    }
  });
  test('Set and get a \'Me\' user', () async {
    try {
      dbHandler.setMe(jamesbondTestUser);
      expect(dbHandler.getMe(), jamesbondTestUser);
      expect(dbHandler.getMe(), isNot(edTestUser));
    } finally {
      await killAll(dbHandler);
    }
  });
}

Future<void> cleanUsers(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`Users`');
}

Future<void> cleanSettings(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`Setting`');
}

Future<void> cleanGuardianRelations(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`GuardianRelations`');
}

Future<void> cleanWeekTemplates(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`WeekTemplates`');
}

Future<void> cleanWeek(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`Weeks`');
}

Future<void> cleanWeekdays(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`Weekdays`');
}

Future<void> cleanPictograms(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`Pictograms`');
}

Future<void> cleanActivities(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`Activities`');
}

Future<void> cleanPictogramRelations(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`PictogramRelations`');
}

Future<void> cleanTimers(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`Timers`');
}

Future<void> cleanFailedOnlineTransactions(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`FailedOnlineTransactions`');
}

Future<void> cleanWeekDayColors(OfflineDbHandler dbHandler) async {
  final Database db = await dbHandler.database;
  await db.delete('`WeekDayColors`');
}

/// Clear the testing database of all information
Future<void> killAll(OfflineDbHandler dbHandler) async {
  await cleanWeekDayColors(dbHandler);
  await cleanFailedOnlineTransactions(dbHandler);
  await cleanTimers(dbHandler);
  await cleanPictogramRelations(dbHandler);
  await cleanActivities(dbHandler);
  await cleanPictograms(dbHandler);
  await cleanWeek(dbHandler);
  await cleanWeekdays(dbHandler);
  await cleanWeekTemplates(dbHandler);
  await cleanGuardianRelations(dbHandler);
  await cleanSettings(dbHandler);
  await cleanUsers(dbHandler);
}
