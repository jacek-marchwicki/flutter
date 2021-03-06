// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' hide Platform;

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';

import 'configuration.dart';
import 'snippets.dart';

const String _kSerialOption = 'serial';
const String _kElementOption = 'element';
const String _kHelpOption = 'help';
const String _kInputOption = 'input';
const String _kLibraryOption = 'library';
const String _kOutputOption = 'output';
const String _kPackageOption = 'package';
const String _kTemplateOption = 'template';
const String _kTypeOption = 'type';
const String _kShowDartPad = 'dartpad';

/// Generates snippet dartdoc output for a given input, and creates any sample
/// applications needed by the snippet.
void main(List<String> argList) {
  const Platform platform = LocalPlatform();
  final Map<String, String> environment = platform.environment;
  final ArgParser parser = ArgParser();
  final List<String> snippetTypes =
      SnippetType.values.map<String>((SnippetType type) => getEnumName(type)).toList();
  parser.addOption(
    _kTypeOption,
    defaultsTo: getEnumName(SnippetType.application),
    allowed: snippetTypes,
    allowedHelp: <String, String>{
      getEnumName(SnippetType.application):
          'Produce a code snippet complete with embedding the sample in an '
          'application template.',
      getEnumName(SnippetType.sample):
          'Produce a nicely formatted piece of sample code. Does not embed the '
          'sample into an application template.',
    },
    help: 'The type of snippet to produce.',
  );
  parser.addOption(
    _kTemplateOption,
    defaultsTo: null,
    help: 'The name of the template to inject the code into.',
  );
  parser.addOption(
    _kOutputOption,
    defaultsTo: null,
    help: 'The output path for the generated snippet application. Overrides '
        'the naming generated by the --package/--library/--element arguments. '
        'Metadata will be written alongside in a .json file. '
        'The basename of this argument is used as the ID',
  );
  parser.addOption(
    _kInputOption,
    defaultsTo: environment['INPUT'],
    help: 'The input file containing the snippet code to inject.',
  );
  parser.addOption(
    _kPackageOption,
    defaultsTo: environment['PACKAGE_NAME'],
    help: 'The name of the package that this snippet belongs to.',
  );
  parser.addOption(
    _kLibraryOption,
    defaultsTo: environment['LIBRARY_NAME'],
    help: 'The name of the library that this snippet belongs to.',
  );
  parser.addOption(
    _kElementOption,
    defaultsTo: environment['ELEMENT_NAME'],
    help: 'The name of the element that this snippet belongs to.',
  );
  parser.addOption(
    _kSerialOption,
    defaultsTo: environment['INVOCATION_INDEX'],
    help: 'A unique serial number for this snippet tool invocation.',
  );
  parser.addFlag(
    _kHelpOption,
    defaultsTo: false,
    negatable: false,
    help: 'Prints help documentation for this command',
  );
  parser.addFlag(
    _kShowDartPad,
    defaultsTo: false,
    negatable: false,
    help: 'Indicates whether DartPad should be included in the snippet\'s '
        'final HTML output. This flag only applies when the type parameter is '
        '"application".',
  );

  final ArgResults args = parser.parse(argList);

  if (args[_kHelpOption]) {
    stderr.writeln(parser.usage);
    exit(0);
  }

  final SnippetType snippetType = SnippetType.values
      .firstWhere((SnippetType type) => getEnumName(type) == args[_kTypeOption], orElse: () => null);
  assert(snippetType != null, "Unable to find '${args[_kTypeOption]}' in SnippetType enum.");

  if (args[_kShowDartPad] == true && snippetType != SnippetType.application) {
    errorExit('${args[_kTypeOption]} was selected, but the --dartpad flag is only valid '
      'for application snippets.');
  }

  if (args[_kInputOption] == null) {
    stderr.writeln(parser.usage);
    errorExit('The --$_kInputOption option must be specified, either on the command '
        'line, or in the INPUT environment variable.');
  }

  final File input = File(args['input']);
  if (!input.existsSync()) {
    errorExit('The input file ${input.path} does not exist.');
  }

  String template;
  if (snippetType == SnippetType.application) {
    if (args[_kTemplateOption] == null || args[_kTemplateOption].isEmpty) {
      stderr.writeln(parser.usage);
      errorExit('The --$_kTemplateOption option must be specified on the command '
          'line for application snippets.');
    }
    template = args[_kTemplateOption].toString().replaceAll(RegExp(r'.tmpl$'), '');
  }

  final String packageName = args[_kPackageOption] != null && args[_kPackageOption].isNotEmpty ? args[_kPackageOption] : null;
  final String libraryName = args[_kLibraryOption] != null && args[_kLibraryOption].isNotEmpty ? args[_kLibraryOption] : null;
  final String elementName = args[_kElementOption] != null && args[_kElementOption].isNotEmpty ? args[_kElementOption] : null;
  final String serial = args[_kSerialOption] != null && args[_kSerialOption].isNotEmpty ? args[_kSerialOption] : null;
  final List<String> id = <String>[];
  if (args[_kOutputOption] != null) {
    id.add(path.basename(path.basenameWithoutExtension(args[_kOutputOption])));
  } else {
    if (packageName != null && packageName != 'flutter') {
      id.add(packageName);
    }
    if (libraryName != null) {
      id.add(libraryName);
    }
    if (elementName != null) {
      id.add(elementName);
    }
    if (serial != null) {
      id.add(serial);
    }
    if (id.isEmpty) {
      errorExit('Unable to determine ID. At least one of --$_kPackageOption, '
          '--$_kLibraryOption, --$_kElementOption, -$_kSerialOption, or the environment variables '
          'PACKAGE_NAME, LIBRARY_NAME, ELEMENT_NAME, or INVOCATION_INDEX must be non-empty.');
    }
  }

  final SnippetGenerator generator = SnippetGenerator();
  stdout.write(generator.generate(
    input,
    snippetType,
    showDartPad: args[_kShowDartPad],
    template: template,
    output: args[_kOutputOption] != null ? File(args[_kOutputOption]) : null,
    metadata: <String, Object>{
      'sourcePath': environment['SOURCE_PATH'],
      'sourceLine': environment['SOURCE_LINE'] != null
          ? int.tryParse(environment['SOURCE_LINE'])
          : null,
      'id': id.join('.'),
      'serial': serial,
      'package': packageName,
      'library': libraryName,
      'element': elementName,
    },
  ));

  exit(0);
}
