import 'dart:convert';

import 'package:api_client/models/model.dart';
import 'package:api_client/models/username_model.dart';
import 'package:api_client/offline_repository/exceptions.dart';
import 'package:api_client/offline_repository/repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'mock_database.dart';

void main() {

  MockDatabase mockDatabase;
  OfflineRepository repository;

  setUp(() {
    mockDatabase  = MockDatabase();
  });

  test('When model not recognized by model factory, throw exception', () async {
    repository = OfflineRepository('', db: mockDatabase);

    when(mockDatabase.query(any,
        distinct: null,
        columns: anyNamed('columns'),
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs')))
        .thenAnswer((_) async =>
    <Map<String, dynamic>>[
      <String, dynamic>{'json': '{"test": "test"}'}
    ]);

    expect(() => repository.get(1), throwsException);
  });

  test('When model exists and is recognized, should return model', () async {
    repository = OfflineRepository(
        (UsernameModel).toString(),
        db: mockDatabase
    );

    final UsernameModel usernameModel = UsernameModel(
      name: 'name',
      role: 'role',
      id: '1',
    );
    final String usernameModelJson =
        json.encode(usernameModel.toJson()).toString();

    when(mockDatabase.query(any,
        distinct: null,
        columns: anyNamed('columns'),
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs')))
        .thenAnswer((_) async =>
    <Map<String, dynamic>>[
      <String, dynamic>{'json': usernameModelJson}
    ]);

    // Test will pass for any id > 0
    final Model actualModel = await repository.get(1);

    expect(actualModel, isInstanceOf<UsernameModel>());
    expect(actualModel.toJson(), equals(usernameModel.toJson()));
    expect(actualModel.getOfflineId(), isNotNull);
    expect(actualModel.getOfflineId(), greaterThan(0));
  });

  test('When id not found, should raise error', () {
    repository = OfflineRepository('', db: mockDatabase);

    when(mockDatabase.query(any,
        distinct: null,
        columns: anyNamed('columns'),
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'))).thenThrow(NotFoundException(''));

    expect(repository.get(1), throwsException);
  });
}