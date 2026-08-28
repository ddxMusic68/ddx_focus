import 'package:flutter_test/flutter_test.dart';
import 'package:ddx_focus/providers/tags_provider.dart';

void main() {
  group('TagsProvider', () {
    late TagsProvider provider;
    var notifications = 0;

    setUp(() {
      provider = TagsProvider();
      notifications = 0;
      provider.addListener(() => notifications++);
    });

    group('addTag', () {
      test('starts empty', () {
        expect(provider.tags, isEmpty);
      });

      test('adds a trimmed tag and notifies listeners', () {
        expect(provider.addTag('  work  '), isTrue);

        expect(provider.tags, ['work']);
        expect(notifications, greaterThan(0));
      });

      test('ignores empty names', () {
        expect(provider.addTag('   '), isFalse);
        expect(provider.tags, isEmpty);
      });

      test('rejects duplicate tags ignoring case', () {
        provider.addTag('Work');

        expect(provider.addTag('work'), isFalse);
        expect(provider.tags, ['Work']);
      });
    });

    group('removeTag', () {
      setUp(() {
        provider.replaceAll(['work', 'study']);
      });

      test('removes a tag case-insensitively', () {
        expect(provider.removeTag('STUDY'), isTrue);

        expect(provider.tags, ['work']);
      });

      test('returns false when the tag is absent', () {
        expect(provider.removeTag('nope'), isFalse);
        expect(provider.tags, hasLength(2));
      });
    });

    group('replaceAll', () {
      test('replaces all tags and notifies listeners', () {
        provider.replaceAll(['alpha', 'beta']);

        expect(provider.tags, ['alpha', 'beta']);
        expect(notifications, greaterThan(0));
      });

      test('clears tags when given an empty list', () {
        provider.replaceAll(['alpha']);
        provider.replaceAll([]);

        expect(provider.tags, isEmpty);
      });
    });

    group('exposed list', () {
      test('cannot be mutated directly', () {
        provider.replaceAll(['x']);

        expect(() => provider.tags.add('y'), throwsUnsupportedError);
      });
    });
  });
}
