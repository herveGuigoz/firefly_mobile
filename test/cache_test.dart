import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firefly/core/storage/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pedantic/pedantic.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:uuid/uuid.dart';

import 'mocks/storage_mock.dart';

class MockBox extends Mock implements Box<dynamic> {}

class MockPathProviderPlatform extends Mock
    // ignore: prefer_mixin
    with
        // ignore: prefer_mixin
        MockPlatformInterfaceMixin
    implements
        PathProviderPlatform {
  MockPathProviderPlatform({
    @required this.temporaryPath,
    @required this.getTemporaryPathCalled,
  });

  final String temporaryPath;
  final VoidCallback getTemporaryPathCalled;

  @override
  Future<String> getTemporaryPath() async {
    getTemporaryPathCalled();
    return temporaryPath;
  }
}

class MyUuidHydrated extends HydratedStateNotifier<String> {
  MyUuidHydrated() : super(Uuid().v4());

  @override
  Map<String, String> toJson(String state) => {'value': state};

  @override
  String fromJson(dynamic json) => json['value'] as String;
}

class MyHydratedCounter extends HydratedStateNotifier<int> {
  MyHydratedCounter() : super(0);

  void increment() => state++;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int fromJson(dynamic json) => json['value'] as int;
}

class MyHydrated extends HydratedStateNotifier<int> {
  MyHydrated([this._id]) : super(0);

  final String _id;

  @override
  String get id => _id;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int fromJson(dynamic json) => json['value'] as int;
}

class MyMultiHydrated extends HydratedStateNotifier<int> {
  MyMultiHydrated(String id)
      : _id = id,
        super(0);

  final String _id;

  @override
  String get id => _id;

  @override
  Map<String, int> toJson(int state) => {'value': state};

  @override
  int fromJson(dynamic json) => json['value'] as int;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HydratedStorage', () {
    final cwd = Directory.current.absolute.path;
    var getTemporaryDirectoryCallCount = 0;

    setUp(() async {
      PathProviderPlatform.instance = MockPathProviderPlatform(
        temporaryPath: cwd,
        getTemporaryPathCalled: () => ++getTemporaryDirectoryCallCount,
      );
    });

    Storage storage;

    tearDown(() async {
      await storage?.clear();
    });

    group('migration', () {
      test('returns correct value when file exists', () async {
        final directory = await getTemporaryDirectory();
        File('${directory.path}/.hydrated_bloc.json')
            .writeAsStringSync(json.encode({
          'CounterBloc': json.encode({'value': 4})
        }));
        storage = await HydratedStorage.build();
        expect(storage.read('CounterBloc')['value'] as int, 4);
      });
    });

    group('build', () {
      setUp(() async {
        await (await HydratedStorage.build()).clear();
        getTemporaryDirectoryCallCount = 0;
      });

      test('calls getTemporaryDirectory when storageDirectory is null',
          () async {
        storage = await HydratedStorage.build();
        expect(getTemporaryDirectoryCallCount, 1);
      });

      test(
          'does not call getTemporaryDirectory '
          'when storageDirectory is null and kIsWeb', () async {
        HydratedStorage.isWeb = true;
        final completer = Completer<void>();
        await runZoned(() {
          HydratedStorage.build().whenComplete(completer.complete);
          return completer.future;
        }, onError: (dynamic _) {});
        HydratedStorage.isWeb = kIsWeb;
        expect(getTemporaryDirectoryCallCount, 0);
      });

      test(
          'does not call getTemporaryDirectory '
          'when storageDirectory is defined', () async {
        storage = await HydratedStorage.build(storageDirectory: Directory(cwd));
        expect(getTemporaryDirectoryCallCount, 0);
      });

      test('reuses existing instance when called multiple times', () async {
        final instanceA = storage = await HydratedStorage.build();
        final beforeCount = getTemporaryDirectoryCallCount;
        final instanceB = await HydratedStorage.build();
        final afterCount = getTemporaryDirectoryCallCount;
        expect(beforeCount, afterCount);
        expect(instanceA, instanceB);
      });

      test('creates internal HiveImpl with correct directory', () async {
        storage = await HydratedStorage.build();
        final box = HydratedStorage.hive?.box<dynamic>('hydrated_box');
        final directory = await getTemporaryDirectory();
        expect(box, isNotNull);
        expect(box.path, p.join(directory.path, 'hydrated_box.hive'));
      });
    });

    group('default constructor', () {
      const key = '__key__';
      const value = '__value__';
      Box box;

      setUp(() {
        box = MockBox();
        storage = HydratedStorage(box);
      });

      group('read', () {
        test('returns null when box is not open', () {
          when(box.isOpen).thenReturn(false);
          expect(storage.read(key), isNull);
        });

        test('returns correct value when box is open', () {
          when(box.isOpen).thenReturn(true);
          when<dynamic>(box.get(any)).thenReturn(value);
          expect(storage.read(key), value);
          verify<dynamic>(box.get(key)).called(1);
        });
      });

      group('write', () {
        test('does nothing when box is not open', () async {
          when(box.isOpen).thenReturn(false);
          await storage.write(key, value);
          verifyNever(box.put(any, any));
        });

        test('puts key/value in box when box is open', () async {
          when(box.isOpen).thenReturn(true);
          await storage.write(key, value);
          verify(box.put(key, value)).called(1);
        });
      });

      group('delete', () {
        test('does nothing when box is not open', () async {
          when(box.isOpen).thenReturn(false);
          await storage.delete(key);
          verifyNever(box.delete(any));
        });

        test('puts key/value in box when box is open', () async {
          when(box.isOpen).thenReturn(true);
          await storage.delete(key);
          verify(box.delete(key)).called(1);
        });
      });

      group('clear', () {
        test('does nothing when box is not open', () async {
          when(box.isOpen).thenReturn(false);
          await storage.clear();
          verifyNever(box.deleteFromDisk());
        });

        test('deletes box when box is open', () async {
          when(box.isOpen).thenReturn(true);
          await storage.clear();
          verify(box.deleteFromDisk()).called(1);
        });
      });
    });

    group('During heavy load', () {
      test('writes key/value pairs correctly', () async {
        const token = 'token';
        storage = await HydratedStorage.build(
          storageDirectory: Directory(cwd),
        );
        await Stream.fromIterable(
          Iterable.generate(120, (i) => i),
        ).asyncMap((i) async {
          final record = Iterable.generate(
            i,
            (i) => Iterable.generate(i, (j) => 'Point($i,$j);').toList(),
          ).toList();

          unawaited(storage.write(token, record));

          storage = await HydratedStorage.build(
            storageDirectory: Directory(cwd),
          );

          final written = storage.read(token) as List<List<String>>;
          expect(written, isNotNull);
          expect(written, record);
        }).drain<dynamic>();
      });
    });

    group('Storage interference', () {
      final temp = p.join(cwd, 'temp');
      final docs = p.join(cwd, 'docs');

      tearDown(() async {
        await Directory(temp).delete(recursive: true);
        await Directory(docs).delete(recursive: true);
      });

      test('Hive and Hydrated default directories', () async {
        Hive.init(docs);
        storage = await HydratedStorage.build(
          storageDirectory: Directory(temp),
        );

        var box = await Hive.openBox<String>('hive');
        await box.put('name', 'hive');
        expect(box.get('name'), 'hive');
        await Hive.close();

        Hive.init(docs);
        box = await Hive.openBox<String>('hive');
        try {
          expect(box.get('name'), isNotNull);
          expect(box.get('name'), 'hive');
        } finally {
          await storage.clear();
          await Hive.close();
        }
      });
    });
  });

  group('Hydrated', () {
    Storage storage;

    setUp(() {
      storage = MockStorage();
      when(storage.write(any, any)).thenAnswer((_) async {});
      HydratedStateNotifier.storage = storage;
    });

    test('reads from storage once upon initialization', () {
      MyHydrated();
      verify<dynamic>(storage.read('MyHydrated')).called(1);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache value exists', () {
      when<dynamic>(storage.read('MyHydratedCounter')).thenReturn(
        {'value': 42},
      );
      final counter = MyHydratedCounter();
      expect(counter.state, 42);
      counter.increment();
      expect(counter.state, 43);
      verify<dynamic>(storage.read('MyHydratedCounter')).called(1);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is empty', () {
      when<dynamic>(storage.read('MyHydratedCounter')).thenReturn(null);
      final counter = MyHydratedCounter();
      expect(counter.state, 0);
      counter.increment();
      expect(counter.state, 1);
      verify<dynamic>(storage.read('MyHydratedCounter')).called(1);
    });

    test(
        'does not read from storage on subsequent state changes '
        'when cache is malformed', () {
      when<dynamic>(storage.read('MyHydratedCounter')).thenReturn('{');
      final counter = MyHydratedCounter();
      expect(counter.state, 0);
      counter.increment();
      expect(counter.state, 1);
      verify<dynamic>(storage.read('MyHydratedCounter')).called(1);
    });

    group('SingleHydrated', () {
      test('should throw StorageNotFound when storage is null', () {
        HydratedStateNotifier.storage = null;
        expect(
          () => MyHydrated(),
          throwsA(isA<StorageNotFound>()),
        );
      });

      test('StorageNotFound overrides toString', () {
        expect(
          const StorageNotFound().toString(),
          'Storage was accessed before it was initialized.\n'
          'Please ensure that storage has been initialized.\n\n'
          'For example:\n\n'
          'HydratedStateNotifier.storage = await HydratedStorage.build();',
        );
      });

      test('storage getter returns correct storage instance', () {
        final storage = MockStorage();
        HydratedStateNotifier.storage = storage;
        expect(HydratedStateNotifier.storage, storage);
      });

      test('should call storage.write when onChange is called', () {
        const nextState = 0;
        final expected = <String, int>{'value': 0};
        final notifier = MyHydrated();
        notifier.state = nextState;

        verify(storage.write('MyHydrated', expected)).called(2);
      });

      test('stores initial state when instantiated', () {
        MyHydrated();
        verify<dynamic>(
          storage.write('MyHydrated', {'value': 0}),
        ).called(1);
      });

      test('initial state should return 0 when fromJson returns null', () {
        when<dynamic>(storage.read('MyHydrated')).thenReturn(null);
        expect(MyHydrated().state, 0);
        verify<dynamic>(storage.read('MyHydrated')).called(1);
      });

      test('initial state should return 0 when deserialization fails', () {
        when<dynamic>(storage.read('MyHydrated')).thenThrow(Exception('oops'));
        expect(MyHydrated().state, 0);
        verify<dynamic>(storage.read('MyHydrated')).called(1);
      });

      test('initial state should return 101 when fromJson returns 101', () {
        when<dynamic>(storage.read('MyHydrated')).thenReturn({'value': 101});

        expect(MyHydrated().state, 101);
        verify<dynamic>(storage.read('MyHydrated')).called(1);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await MyHydrated().clear();
          verify(storage.delete('MyHydrated')).called(1);
        });
      });
    });

    group('MultiHydrated', () {
      test('initial state should return 0 when fromJson returns null', () {
        when<dynamic>(storage.read('MyMultiHydratedA')).thenReturn(null);
        expect(MyMultiHydrated('A').state, 0);
        verify<dynamic>(storage.read('MyMultiHydratedA')).called(1);

        when<dynamic>(storage.read('MyMultiHydratedB')).thenReturn(null);
        expect(MyMultiHydrated('B').state, 0);
        verify<dynamic>(storage.read('MyMultiHydratedB')).called(1);
      });

      test('initial state should return 101/102 when fromJson returns 101/102',
          () {
        when<dynamic>(storage.read('MyMultiHydratedA'))
            .thenReturn({'value': 101});
        expect(MyMultiHydrated('A').state, 101);
        verify<dynamic>(storage.read('MyMultiHydratedA')).called(1);

        when<dynamic>(storage.read('MyMultiHydratedB'))
            .thenReturn({'value': 102});
        expect(MyMultiHydrated('B').state, 102);
        verify<dynamic>(storage.read('MyMultiHydratedB')).called(1);
      });

      group('clear', () {
        test('calls delete on storage', () async {
          await MyMultiHydrated('A').clear();
          verify(storage.delete('MyMultiHydratedA')).called(1);
          verifyNever(storage.delete('MyMultiHydratedB'));

          await MyMultiHydrated('B').clear();
          verify(storage.delete('MyMultiHydratedB')).called(1);
        });
      });
    });

    group('MyUuidHydrated', () {
      test('stores initial state when instantiated', () {
        MyUuidHydrated();
        verify<dynamic>(storage.write('MyUuidHydrated', any)).called(1);
      });

      test('correctly caches computed initial state', () {
        dynamic cachedState;
        when<dynamic>(storage.read('MyUuidHydrated')).thenReturn(cachedState);
        MyUuidHydrated();
        cachedState =
            verify(storage.write('MyUuidHydrated', captureAny)).captured.last;
        when<dynamic>(storage.read('MyUuidHydrated')).thenReturn(cachedState);
        MyUuidHydrated();
        final dynamic initialStateB =
            verify(storage.write('MyUuidHydrated', captureAny)).captured.last;
        expect(initialStateB, cachedState);
      });
    });
  });
}
