import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/data_models.dart';
import '../widgets/wavy_header.dart';
import '../widgets/subject_marks_tab.dart';
import '../widgets/final_sheet_tab.dart';
import '../widgets/summary_sheet_tab.dart';

class TermWorkspaceScreen extends StatefulWidget {
  final TermSetup term;
  final List<SubjectSetup> subjects;
  final List<StudentRow> allStudents;
  const TermWorkspaceScreen({super.key, required this.term, required this.subjects, required this.allStudents});
  @override
  State<TermWorkspaceScreen> createState() => _TermWorkspaceScreenState();
}

class _TermWorkspaceScreenState extends State<TermWorkspaceScreen> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _captureAndShareImage() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/Term_Capture.png');
        await file.writeAsBytes(pngBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Image Saved to Gallery');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image Saved to Gallery!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            WavyHeader(
              title: widget.term.name,
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.popUntil(context, (route) => route.isFirst)),
              actions: [
                TextButton.icon(onPressed: _captureAndShareImage, icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18), label: const Text("Download this page", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
              ],
            ),
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary, unselectedLabelColor: Colors.grey, indicatorColor: Theme.of(context).colorScheme.primary, indicatorWeight: 3, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                const Tab(icon: Icon(Icons.edit_note), text: "Subject Marks"), 
                Tab(icon: const Icon(Icons.assignment_turned_in), text: "${widget.term.name} Final"), 
                Tab(icon: const Icon(Icons.analytics), text: "${widget.term.name} Summary")
              ],
            ),
            Expanded(
              child: RepaintBoundary(
                key: _globalKey,
                child: Container(
                  color: Colors.white,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SubjectMarksTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents),
                      FinalSheetTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents),
                      SummarySheetTabWidget(termId: widget.term.id, subjects: widget.subjects, students: widget.allStudents),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
