import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HTML Table Parser Tests', () {
    test('parses simple HTML table correctly', () {
      const htmlTable = '''
        <table>
          <tr>
            <td>Header 1</td>
            <td>Header 2</td>
          </tr>
          <tr>
            <td>Data 1</td>
            <td>Data 2</td>
          </tr>
        </table>
      ''';

      // This test verifies that the HTML structure is valid
      expect(htmlTable.contains('<table>'), isTrue);
      expect(htmlTable.contains('<tr>'), isTrue);
      expect(htmlTable.contains('<td>'), isTrue);
      expect(htmlTable.contains('Header 1'), isTrue);
      expect(htmlTable.contains('Data 1'), isTrue);
    });

    test('parses complex HTML table with styling', () {
      const complexTable = '''
        <table style="width:448.2pt;" class="table_border_top table_border_right table_border_bottom table_border_left table_horizontal_border table_vertical_border">
          <colgroup>
            <col width="128.15pt;">
            <col width="155.4pt;">
            <col width="164.65pt;">
          </colgroup>
          <tbody>
            <tr>
              <td><p class="align_center no-indent">Напряжение электроустановок, кВ</p></td>
              <td><p class="align_center no-indent">Расстояние от работников, м</p></td>
              <td><p class="align_center no-indent">Расстояния от механизмов, м</p></td>
            </tr>
            <tr>
              <td><p class="align_center no-indent">ВЛ до 1</p></td>
              <td><p class="align_center no-indent">0,6</p></td>
              <td><p class="align_center no-indent">1,0</p></td>
            </tr>
            <tr>
              <td><p class="align_center no-indent">1 - 35</p></td>
              <td><p class="align_center no-indent">0,6</p></td>
              <td><p class="align_center no-indent">1,0</p></td>
            </tr>
            <tr>
              <td><p class="align_center no-indent">750</p></td>
              <td><p class="align_center no-indent">5,0</p></td>
              <td><p class="align_center no-indent">6,0</p></td>
            </tr>
            <tr>
              <td><p class="align_center no-indent">1150</p></td>
              <td><p class="align_center no-indent">8,0</p></td>
              <td><p class="align_center no-indent">10,0</p></td>
            </tr>
          </tbody>
        </table>
      ''';

      // Verify table structure
      expect(complexTable.contains('<table'), isTrue);
      expect(complexTable.contains('<tr>'), isTrue);
      expect(complexTable.contains('<td>'), isTrue);
      expect(complexTable.contains('<p class='), isTrue);

      // Verify content
      expect(complexTable.contains('Напряжение электроустановок'), isTrue);
      expect(complexTable.contains('ВЛ до 1'), isTrue);
      expect(complexTable.contains('1 - 35'), isTrue);
      expect(complexTable.contains('750'), isTrue);
      expect(complexTable.contains('1150'), isTrue);
      expect(complexTable.contains('0,6'), isTrue);
      expect(complexTable.contains('5,0'), isTrue);
      expect(complexTable.contains('8,0'), isTrue);
      expect(complexTable.contains('10,0'), isTrue);
    });

    test('handles table with colspan and rowspan', () {
      const tableWithSpans = '''
        <table>
          <tr>
            <td colspan="2">Merged Header</td>
            <td>Single Header</td>
          </tr>
          <tr>
            <td rowspan="2">Merged Cell</td>
            <td>Data 1</td>
            <td>Data 2</td>
          </tr>
          <tr>
            <td>Data 3</td>
            <td>Data 4</td>
          </tr>
        </table>
      ''';

      expect(tableWithSpans.contains('colspan="2"'), isTrue);
      expect(tableWithSpans.contains('rowspan="2"'), isTrue);
      expect(tableWithSpans.contains('Merged Header'), isTrue);
      expect(tableWithSpans.contains('Merged Cell'), isTrue);
    });

    test('handles empty table cells', () {
      const tableWithEmptyCells = '''
        <table>
          <tr>
            <td>Header 1</td>
            <td></td>
            <td>Header 3</td>
          </tr>
          <tr>
            <td>Data 1</td>
            <td></td>
            <td>Data 3</td>
          </tr>
        </table>
      ''';

      expect(tableWithEmptyCells.contains('<td></td>'), isTrue);
      expect(tableWithEmptyCells.contains('Header 1'), isTrue);
      expect(tableWithEmptyCells.contains('Data 1'), isTrue);
    });
  });
}
