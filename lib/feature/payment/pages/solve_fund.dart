import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
import 'package:solve_tutor/feature/payment/service/payment_service.dart';
import 'package:solve_tutor/feature/profile/components/webview.dart';
import 'package:solve_tutor/widgets/sizer.dart';

class SolveFundPage extends StatefulWidget {
  const SolveFundPage({super.key});
  @override
  State<SolveFundPage> createState() => _SolveFundPageState();
}

class _SolveFundPageState extends State<SolveFundPage> {
  @override
  late AuthProvider authProvider;
  String? balance;
  @override
  void initState() {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    super.initState();
    setState(() {
      balance = authProvider.wallet!.balance.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: CustomColors.white,
        elevation: 6,
        title: Text(
          'SOLVE Coin',
          style: CustomStyles.bold22Black363636,
        ),
        leading: InkWell(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.arrow_back, color: Colors.grey),
        ),
      ),
      body: SafeArea(
        child: Form(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey,
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                          width: Sizer(context).w,
                          height: Sizer(context).h * .01),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'จำนวนเหรียญ:',
                            style: TextStyle(
                              color: Color(0xFF363636),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // const SizedBox(width: 8),
                          // Container(
                          //   child: Column(
                          //     mainAxisSize: MainAxisSize.min,
                          //     mainAxisAlignment: MainAxisAlignment.start,
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Text(
                          //         'help',
                          //         textAlign: TextAlign.center,
                          //         style: TextStyle(
                          //           color: Color(0xFF878787),
                          //           fontSize: 16,
                          //           fontFamily: 'Material Icons',
                          //           fontWeight: FontWeight.w400,
                          //           height: 0.06,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const ShapeDecoration(
                                      shape: OvalBorder(
                                        side: BorderSide(
                                            width: 2, color: Color(0xFF20B153)),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 2,
                                  top: 2,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image:
                                            AssetImage(ImageAssets.solvePoint),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            balance ?? '0',
                            style: const TextStyle(
                              color: Color(0xFF363636),
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          await authProvider.getWallet();
                          setState(() {
                            balance = authProvider.wallet!.balance.toString();
                          });
                        },
                        child: const Text(
                          'อัพเดทข้อมูล',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF878787),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ซื้อเหรียญ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF363636),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ratePointCard(
                          context: context,
                          uid: authProvider.uid!,
                          point: 600,
                          rate: 90),
                      const Divider(thickness: 2),
                      const SizedBox(height: 8),
                      ratePointCard(
                          context: context,
                          uid: authProvider.uid!,
                          point: 1200,
                          rate: 180),
                      const Divider(thickness: 2),
                      const SizedBox(height: 8),
                      ratePointCard(
                          context: context,
                          uid: authProvider.uid!,
                          point: 1800,
                          rate: 270),
                      const Divider(thickness: 2),
                      const SizedBox(height: 8),
                      ratePointCard(
                          context: context,
                          uid: authProvider.uid!,
                          point: 2400,
                          rate: 360),
                      const Divider(thickness: 2),
                      const SizedBox(height: 8),
                      ratePointCard(
                          context: context,
                          uid: authProvider.uid!,
                          point: 3000,
                          rate: 450),
                      const Divider(thickness: 2),
                      const SizedBox(height: 8),
                      ratePointCard(
                          context: context,
                          uid: authProvider.uid!,
                          point: 6000,
                          rate: 900),
                      const Divider(thickness: 2),
                      const SizedBox(height: 8),
                      ratePointCard(
                          context: context,
                          uid: authProvider.uid!,
                          point: 9000,
                          rate: 1350),
                      const Divider(thickness: 2),
                      const SizedBox(height: 8),
                      ratePointCard(
                          context: context,
                          uid: authProvider.uid!,
                          point: 12000,
                          rate: 1800),
                      const Divider(thickness: 2),
                      const SizedBox(height: 8),
                      ratePointCard(
                          context: context,
                          uid: authProvider.uid!,
                          point: 18000,
                          rate: 2700),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.all(15),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เงื่อนไขการใช้บริการ:',
                        style: TextStyle(
                          color: Color(0xFF363636),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 0.10,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    'Lorem ipsum dolor sit amet consectetur. Nunc urna aenean lorem arcu dolor vitae amet. Eget dolor elit purus hendrerit. Pretium egestas mattis elit morbi. Imperdiet augue et mattis vehicula tortor. Morbi sed arcu scelerisque arcu ipsum integer eget. Ut massa turpis quis est gravida pulvinar mattis egestas leo. Mattis lacus...',
                                style: TextStyle(
                                  color: Color(0xFF878787),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 0,
                                ),
                              ),
                              TextSpan(
                                text: 'อ่านต่อ',
                                style: TextStyle(
                                    color: Color(0xFF878787),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget ratePointCard(
    {required BuildContext context,
    required String uid,
    required int point,
    required int rate,
    String? detail}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const ShapeDecoration(
                                shape: OvalBorder(
                                  side: BorderSide(
                                      width: 2, color: Color(0xFF20B153)),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 4,
                            top: 4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(ImageAssets.solvePoint),
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SizedBox(
                        child: Text(
                          '$point เหรียญ',
                          style: const TextStyle(
                            color: Color(0xFF363636),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              detail != null ? const SizedBox(height: 4) : const SizedBox(),
              detail != null
                  ? Container(
                      padding: const EdgeInsets.only(left: 28),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail,
                            style: const TextStyle(
                              color: Color(0xFF878787),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () async {
            var body = {
              "ProductImage": "",
              "ProductName": "SP_$uid",
              "ProductDescription":
                  "$point Solve Point | Price: $rate | SP_$uid",
              "PaymentLimit": "",
              // "StartDate": "01/10/2023 00:00:00",
              // "ExpiredDate": "01/10/2024 23:59:59",
              "Currency": "THB",
              "Amount": rate * 100
            };
            var res = await PaymentService().generateLink(body);
            print(res['data']['paymentUrl']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WebViewScreen(url: res['data']['paymentUrl']),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: ShapeDecoration(
              color: const Color(0xFF20B153),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '฿ ${rate}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
