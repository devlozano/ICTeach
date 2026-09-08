import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:icteach/utils/lrn_csv_parser.dart';
import 'package:icteach/services/lrn_csv_import_service.dart';

void main() {
  List<LrnCsvRecord> parse(String text) =>
      LrnCsvParser.parseBytes(utf8.encode(text));
  String id(int value) => value.toString().padLeft(12, '0');
  test('UTF-8 BOM, CRLF, Unicode and reordered headers are supported', () {
    final record = parse(
      '\uFEFFLast Name,LRN,Middle Name,First Name\r\nDela Peña,000000000001,,José\r\n',
    ).single;
    expect(record.lrn, '000000000001');
    expect(record.firstName, 'José');
    expect(record.lastName, 'Dela Peña');
    expect(record.middleName, '');
  });
  test('quoted commas, doubled quotes and embedded line breaks are parsed', () {
    final record = parse(
      'LRN,First Name,Last Name,Middle Name\n123456789012,"Ana\nMaria","Santos, Jr.","Jo""se"',
    ).single;
    expect(record.firstName, 'Ana Maria');
    expect(record.lastName, 'Santos, Jr.');
    expect(record.middleName, 'Jo"se');
  });
  test(
    'headerless files retain first student and allow optional middle name',
    () {
      final records = parse('000000000000,A,B\n999999999999,C,D,E');
      expect(records.length, 2);
      expect(records.first.lrn, '000000000000');
      expect(records.last.lrn, '999999999999');
    },
  );
  test('blank rows and trailing line endings are ignored', () {
    expect(
      parse(
        '\nLRN,first_name,last_name\r\n\r\n123456789012,A,B\r\n,,\r\n',
      ).length,
      1,
    );
  });
  for (final input in [
    '',
    ' \n\r\n',
    'LRN,First Name,Last Name',
    'LRN,Name\n123456789012,A',
    'LRN,LRN,First Name,Last Name\n123456789012,123456789012,A,B',
    '12345678901,A,B',
    '1234567890123,A,B',
    '1.23456789012E+11,A,B',
    '12345678901x,A,B',
    '123456789012,,B',
    '123456789012,A, ',
    '123456789012,A,B,extra,unexpected',
    'LRN,First Name,Last Name\n123456789012,A',
    '123456789012,"A,B',
    '123456789012,"A"oops,B',
    '123456789012,A"bad,B',
    '123456789012,A,B\n123456789012,C,D',
  ]) {
    test('invalid CSV rejected: ${input.replaceAll('\n', ' / ')}', () {
      expect(() => parse(input), throwsFormatException);
    });
  }
  test('name length boundary is validated', () {
    expect(parse('123456789012,${'a' * 150},B').single.firstName.length, 150);
    expect(() => parse('123456789012,${'a' * 151},B'), throwsFormatException);
  });
  test('file size and invalid text encoding are rejected', () {
    expect(
      () => LrnCsvParser.parseBytes(List.filled(LrnCsvParser.maxBytes + 1, 32)),
      throwsFormatException,
    );
    expect(
      () => LrnCsvParser.parseBytes([0xff, 0xfe, 0, 0]),
      throwsFormatException,
    );
    final valid = utf8.encode('123456789012,A,B');
    expect(
      LrnCsvParser.parseBytes([
        ...valid,
        ...List.filled(LrnCsvParser.maxBytes - valid.length, 32),
      ]).length,
      1,
    );
  });
  test('10,000 records accepted, 10,001 rejected', () {
    final csv = List.generate(10000, (i) => '${id(i)},A,B').join('\n');
    expect(parse(csv).length, 10000);
    expect(() => parse('$csv\n${id(10000)},A,B'), throwsFormatException);
  });
  test(
    'large imports are chunked with accurate progress and skipped totals',
    () async {
      final chunks = <int>[], progress = <int>[];
      final service = LrnCsvImportService(
        createMissing: (rows) async {
          chunks.add(rows.length);
          return rows.length - 1;
        },
      );
      final records = List.generate(
        501,
        (i) => LrnCsvRecord(id(i), 'A', 'B', ''),
      );
      final result = await service.importRecords(
        records,
        onProgress: (processed, total) {
          progress.add(processed);
          expect(total, 501);
        },
      );
      expect(chunks, [100, 100, 100, 100, 100, 1]);
      expect(progress, [100, 200, 300, 400, 500, 501]);
      expect(result.added, 495);
      expect(result.skipped, 6);
    },
  );
  test('empty import performs no writes', () async {
    var calls = 0;
    final result = await LrnCsvImportService(
      createMissing: (rows) async {
        calls++;
        return 0;
      },
    ).importRecords([]);
    expect(calls, 0);
    expect(result.added, 0);
    expect(result.skipped, 0);
  });
  test(
    'failure reports confirmed progress and retry skips prior inserts',
    () async {
      final stored = <String>{};
      var calls = 0;
      final records = List.generate(
        205,
        (i) => LrnCsvRecord(id(i), 'A', 'B', ''),
      );
      final service = LrnCsvImportService(
        createMissing: (rows) async {
          calls++;
          if (calls == 2) throw StateError('offline');
          return rows.where((r) => stored.add(r.lrn)).length;
        },
      );
      await expectLater(
        service.importRecords(records),
        throwsA(
          isA<LrnImportFailure>().having(
            (e) => e.added,
            'confirmed additions',
            100,
          ),
        ),
      );
      final retry = await service.importRecords(records);
      expect(retry.added, 105);
      expect(retry.skipped, 100);
      expect(stored.length, 205);
    },
  );
}
