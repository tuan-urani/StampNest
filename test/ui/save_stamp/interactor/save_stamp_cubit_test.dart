import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stamp_camera/src/api/stampverse_api.dart';
import 'package:stamp_camera/src/core/model/stamp_shape_type.dart';
import 'package:stamp_camera/src/core/repository/stampverse_repository.dart';
import 'package:stamp_camera/src/ui/save_stamp/interactor/save_stamp_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StampverseRepository repository;
  late SaveStampCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    repository = StampverseRepository(
      api: StampverseApi(dio: Dio()),
      preferences: preferences,
    );
    cubit = SaveStampCubit(repository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('saveStamp stores stamped image and source image together', () async {
    final bool saved = await cubit.saveStamp(
      stampedImageUrl: 'data:image/png;base64,stamped',
      sourceImageUrl: 'data:image/png;base64,source',
      shapeType: StampShapeType.scallop,
      rawName: 'Test',
      rawCollection: 'Collection',
    );

    expect(saved, isTrue);

    final stamps = await repository.readCache();
    expect(stamps, isNotEmpty);
    expect(stamps.first.imageUrl, 'data:image/png;base64,stamped');
    expect(stamps.first.sourceImageUrl, 'data:image/png;base64,source');
  });
}
