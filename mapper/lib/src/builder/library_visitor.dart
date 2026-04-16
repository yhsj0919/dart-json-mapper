import 'package:analyzer/dart/element/element.dart';

import '../model/annotations.dart';

class LibraryVisitor {
  Map<num, ClassElement> visitedPublicClassElements = {};
  Map<num, ClassElement> visitedPublicAnnotatedClassElements = {};
  Map<num, EnumElement> visitedPublicAnnotatedEnumElements = {};
  Map<String, LibraryElement?> visitedLibraries = {};

  final _annotationClassName = jsonSerializable.runtimeType.toString();
  String? packageName;

  LibraryVisitor(this.packageName);

  List<InterfaceElement> get visitedPublicAnnotatedElements {
    return [
      ...visitedPublicAnnotatedClassElements.values,
      ...visitedPublicAnnotatedEnumElements.values
    ];
  }

  void visitLibrary(LibraryElement element) {
    _visitLibrary(element);
  }

  void _visitClassElement(ClassElement element) {
    if (!element.isPrivate &&
        !visitedPublicClassElements.containsKey(element.id)) {
      visitedPublicClassElements.putIfAbsent(element.id, () => element);
      if (_hasTargetAnnotation(element)) {
        visitedPublicAnnotatedClassElements.putIfAbsent(
            element.id, () => element);
      }
    }
  }

  void _visitEnumElement(EnumElement element) {
    if (!element.isPrivate &&
        !visitedPublicAnnotatedEnumElements.containsKey(element.id) &&
        _hasTargetAnnotation(element)) {
      visitedPublicAnnotatedEnumElements.putIfAbsent(element.id, () => element);
    }
  }

  bool _hasTargetAnnotation(Element element) {
    return element.metadata.annotations.any((meta) =>
        meta.computeConstantValue()?.type?.getDisplayString() ==
        _annotationClassName);
  }

  void _visitLibrary(LibraryElement? element) {
    final identifier = element?.identifier;
    if (identifier != null &&
        !visitedLibraries.containsKey(identifier) &&
        (identifier.startsWith('asset:') ||
            identifier.startsWith(packageName!))) {
      visitedLibraries.putIfAbsent(identifier, () => element);
      for (final classElement in element!.classes) {
        _visitClassElement(classElement);
      }
      for (final enumElement in element.enums) {
        _visitEnumElement(enumElement);
      }
      for (final libraryExport in element.firstFragment.libraryExports) {
        _visitLibrary(libraryExport.exportedLibrary);
      }
      for (final libraryImport in element.firstFragment.libraryImports) {
        _visitLibrary(libraryImport.importedLibrary);
      }
    }
  }
}
