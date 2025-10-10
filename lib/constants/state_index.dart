import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/authentication/service/setting_provider.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_controller.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_live_controller.dart';
import 'package:solve_tutor/feature/calendar/controller/document_controller.dart';
import 'package:solve_tutor/feature/calendar/controller/student_controller.dart';
import 'package:solve_tutor/feature/chat/service/chat_provider.dart';
import 'package:solve_tutor/feature/class/services/class_provider.dart';
import 'package:solve_tutor/feature/notification/student_provider.dart';
import 'package:solve_tutor/feature/order/service/order_mock_provider.dart';

import '../feature/notification/answer_provider.dart';
import '../feature/notification/notification_provider.dart';

final List<SingleChildWidget> stateIndex = [
  ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
  ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
  ChangeNotifierProvider<OrderMockProvider>(create: (_) => OrderMockProvider()),
  Provider<SettingProvider>(create: (_) => SettingProvider()),
  ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
  ChangeNotifierProvider(create: (context) => CourseController()),
  ChangeNotifierProvider(create: (context) => CourseLiveController()),
  ChangeNotifierProvider(create: (context) => DocumentController()),
  ChangeNotifierProvider(create: (context) => StudentController()),
  ChangeNotifierProvider(create: (_) => NotificationProvider()),
  ChangeNotifierProvider(create: (_) => StudentProvider()),
  ChangeNotifierProvider(create: (_) => AnswerProvider()),
];
