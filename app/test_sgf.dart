import 'lib/utils/sgf_parser.dart';
import 'lib/utils/sgf_writer.dart';

void main() {
  String sgf = "(;FF[4]GM[1]SZ[19]PB[Black]PW[White]TR[ab][cd]LB[ef:A];B[pd]TR[ee])";
  
  print('Parsing...');
  var session = SgfParser.parse(sgf);
  print('Root node triangles: ${session.rootNode.triangleMarks}');
  print('Root node labels: ${session.rootNode.labels}');
  print('Child 1 triangles: ${session.rootNode.children.first.triangleMarks}');
  
  print('\nRe-exporting...');
  print(SgfWriter.write(session));
}
