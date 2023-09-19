import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_live_controller.dart';
import 'package:solve_tutor/feature/calendar/controller/document_controller.dart';
import 'package:solve_tutor/feature/calendar/helper/utility_helper.dart';
import 'package:solve_tutor/feature/calendar/model/document_model.dart';
import 'package:solve_tutor/feature/calendar/pages/update_document.dart';
import 'package:solve_tutor/feature/calendar/widgets/dropdown.dart';
import 'package:solve_tutor/feature/calendar/widgets/widgets.dart';
import 'package:solve_tutor/feature/cheet/pages/my_document.dart';

class DialogFileManagerLive extends StatefulWidget {
  DialogFileManagerLive({Key? key, required this.tutorId}) : super(key: key);
  String tutorId;

  @override
  State<DialogFileManagerLive> createState() => _DialogFileManagerLiveState();
}

class _DialogFileManagerLiveState extends State<DialogFileManagerLive> {
  final util = UtilityHelper();
  var documentController = DocumentController();
  var courseController = CourseLiveController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  // Future<List<DocumentModel>>? _future;

  var selectedLevel = '';
  var selectedSubject = '';

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    documentController =
        Provider.of<DocumentController>(context, listen: false);
    courseController =
        Provider.of<CourseLiveController>(context, listen: false);
    await documentController.refreshDocumentListByTutorId(widget.tutorId);
    await courseController.getLevels();
    await courseController.getSubjects();
  }

  @override
  void dispose() {
    super.dispose();
    courseController.courseFilter.clear();
    courseController.selectedDocumentIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    documentController.initialize();
    return Consumer<DocumentController>(builder: (_, document, child) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: CustomColors.grayE5E6E9,
          elevation: 6,
          title: Text(
            'กรุณาเลือกเอกสารประกอบการสอน',
            style: CustomStyles.bold18Black363636,
          ),
          leading: InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.close, color: Colors.grey),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () async {
              await document.getDocumentListByTutorId(widget.tutorId);
              Future.delayed(const Duration(seconds: 1));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _titleDocument(),
                S.h(10.0),
                if (util.isTablet()) ...[
                  Row(
                    children: [
                      Expanded(flex: 3, child: _textFieldFilter()),
                      Expanded(flex: 1, child: _dropdownLevel()),
                      S.w(10.0),
                      Expanded(flex: 1, child: _dropdownSubject()),
                    ],
                  ),
                ] else ...[
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child:  Column(children: [])),
                ],
                Expanded(
                  child: document.isLoading
                      ?  Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Text('กำลังโหลด...'),
                            ),
                          ],
                        )
                      : listMyCourse(
                          document.documentListFilter.isNotEmpty
                              ? document.documentListFilter
                              : document.documentList,
                        ),
                ),
                _bottom()
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _titleDocument() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "เอกสารของฉัน",
            style: CustomStyles.med14Black363636.copyWith(fontSize: 22),
          ),
          _createDocument()
        ],
      ),
    );
  }

  Widget _createDocument() {
    return OutlinedButton.icon(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateDocumentForm(
                documentActionType: DocumentActionType.create,
                documentId: '',
                tutorId: widget.tutorId),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      icon: const Icon(
        Icons.download,
        size: 24.0,
        color: Colors.grey,
      ),
      label: Text(
        'อัพโหลดเอกสาร',
        style: CustomStyles.med14Black363636,
      ),
    );
  }

  Widget _textFieldFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextFormField(
        controller: documentController.keywordTextEditingController,
        textAlignVertical: TextAlignVertical.bottom,
        maxLines: 1,
        style: CustomStyles.med14Black363636,
        decoration: InputDecoration(
          hintText: 'ค้นหา...',
          hintStyle: CustomStyles.med14Black363636
              .copyWith(color: CustomColors.grayCFCFCF),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (value) {},
      ),
    );
  }

  Widget _dropdownLevel() {
    return Dropdown(
      selectedValue: selectedSubject,
      items: courseController.subjects,
      hintText: '-- เลือกหมวดหมู่ --',
      onChanged: (value) {
        selectedSubject = value ?? '';
        debugPrint(value);
        courseController.courseFilter = courseController.courseList
            .where((element) => element.subjectId == value)
            .toList();
      },
    );
  }

  Widget _dropdownSubject() {
    return Dropdown(
      selectedValue: selectedSubject,
      items: courseController.subjects,
      hintText: '-- เลือกหมวดหมู่ --',
      onChanged: (value) {
        selectedSubject = value ?? '';
        debugPrint(value);
        courseController.courseFilter = courseController.courseList
            .where((element) => element.subjectId == value)
            .toList();
      },
    );
  }

  Widget listMyCourse(List<DocumentModel> documents) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 2 / 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 8,
          children: List.generate(documents.length, (index) {
            return GestureDetector(onTap: () async {
              await courseController.setSelectedDocument(index);
              courseController.courseData?.document = documents[index];
              courseController.courseData?.documentId = documents[index].id;
            }, child:
                Consumer<CourseLiveController>(builder: (_, course, child) {
              return Column(
                children: [
                  (documents[index].data?.docFiles?.isEmpty == true)
                      ? Expanded(
                          child: Image.asset(
                            ImageAssets.emptyCourse,
                            width: double.infinity,
                            fit: BoxFit.fitHeight,
                          ),
                        )
                      : Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(10.0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CachedNetworkImage(
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      border: Border.all(color: Colors.grey),
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  imageUrl:
                                      documents[index].data?.docFiles?.first ??
                                          '',
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    color: course.selectedDocumentIndex != index
                                        ? Colors.transparent
                                        : Colors.black.withOpacity(0.5),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      documents[index].data?.documentName ?? '',
                      style: CustomStyles.med14Gray878787.copyWith(
                        color: course.selectedDocumentIndex != index
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            }));
          }).toList()),
    );
  }

  _bottom() {
    return Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        width: double.infinity,
        color: CustomColors.grayE5E6E9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_backToDocument(), _chooseDocButton()],
        ));
  }

  Widget _backToDocument() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.arrow_back,
          size: 20, color: CustomColors.gray878787),
      label: Text(
        "ย้อนกลับ",
        style: CustomStyles.med14Gray878787,
      ),
      onPressed: () async {
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  Widget _chooseDocButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.green20B153,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      onPressed: () {
        if (courseController.selectedDocumentIndex != null) {
          Navigator.of(context).pop(courseController.courseData?.document?.id);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CustomStrings.choose,
            style: CustomStyles.med14Gray878787.copyWith(
              color: CustomColors.white,
            ),
          ),
          S.w(5),
          const Icon(
            Icons.arrow_forward,
            size: 20,
            color: CustomColors.white,
          ), //
        ],
      ),
    );
  }
}
