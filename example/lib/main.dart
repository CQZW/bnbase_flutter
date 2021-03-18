import 'package:bnbase_flutter/bnbase_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  Testvc xxx = Testvc();

  BaseNavVC vvvv = BaseNavVC(xxx);
  runApp(vvvv.getView());
}

class Testvc extends BaseVC {
  Testvc() {
    mPageName = 'Testvc';
  }

  @override
  Widget makePageBody(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Container(
          height: 50,
        ),
        TextButton(
            onPressed: () {
              Testvc2 aaa = Testvc2();
              //pushToVCFade(aaa);
              pushToTransparentVCUpTo(aaa);
            },
            child: Text("PUSH")),
        TextButton(
            onPressed: () {
              hudShowLoading("loading");
              hudShowSuccessMsg("success");
              Future.delayed(Duration(seconds: 3), () {
                hudDismiss();
              });
            },
            child: Text("show loading")),
        TextButton(
            onPressed: () {
              hudShowSuccessMsg("success");
            },
            child: Text("show success")),
        TextButton(
            onPressed: () {
              hudShowInfoMsg("info");
            },
            child: Text("show info")),
      ],
    ));
  }
}

class Testvc2 extends BaseVC {
  Testvc2() {
    mPageName = 'Testvc2';
  }
  @override
  PreferredSizeWidget makeTopBar(BuildContext context) {
    return AppBar(
      title: Text("dd"),
      centerTitle: true,
    );
  }

  @override
  Widget makePageBody(BuildContext context) {
    return Center(
        child: TextButton(
            onPressed: () {
              popBack();
            },
            child: Text("POP")));
  }
}
