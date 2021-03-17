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
        child: TextButton(
            onPressed: () {
              Testvc2 aaa = Testvc2();
              pushToVCFade(aaa);
            },
            child: Text("PUSH")));
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
