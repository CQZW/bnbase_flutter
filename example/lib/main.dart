import 'dart:developer';

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
            onPressed: () async {
              Testvc2 aaa = Testvc2();
              var v = await pushToVCFade(aaa);
              vclog("push wait:$v");
            },
            child: Text("PUSH")),
        TextButton(
            onPressed: () {
              Testvc2 aaa = Testvc2();
              setToVC(aaa);
            },
            child: Text("SET")),
        TextButton(
            onPressed: () {
              Testvc2 aaa = Testvc2();
              setToVC(aaa);
            },
            child: Text("POP")),
        TextButton(
            onPressed: () {
              Testvc2 aaa = Testvc2();
              pushToTransparentVCUpTo(aaa);
            },
            child: Text("pushToTransparentVCUpTo")),
        TextButton(
            onPressed: () {
              hudShowLoading("loading");
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
        child: Column(
      children: [
        TextButton(
            onPressed: () {
              Testvc2 vvv = Testvc2();
              pushToVC(vvv);
            },
            child: Text("SET")),
        TextButton(
            onPressed: () {
              popBack("d");
            },
            child: Text("POP")),
      ],
    ));
  }
}
