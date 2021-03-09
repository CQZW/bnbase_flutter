import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';

///视图控制器.
abstract class ViewCtr {
  BuildContext? _context;

  ///获取context...
  BuildContext? get mContext => _context;

  BaseState? _state;

  ///获取媒体数据
  MediaQueryData get mMediaQueryData => MediaQuery.of(mContext!);

  ///显示调试banner
  bool get mShowDebugBanner => false;

  ///衔接state的 build 方法,将控件布局引入到控制器
  Widget vcBuildWidget(BuildContext context, BaseState state) {
    _context = context;
    _state = state;
    return realBuildWidget(context);
  }

  ///控制器的真正build方法
  Widget realBuildWidget(BuildContext context);

  ///导出控制器真正的布局数据
  Widget getView({Key? key}) => BaseView(key: key, vc: this);

  ///控制器更新数据,就是setstate
  void updateUI() => _state?.setState(() {});

  @mustCallSuper
  void onInitVC() {
    vclog("onInitVC");
  }

  ///调试重新热加载,reassemble被执行
  @mustCallSuper
  void onDebugReLoad() {
    vclog("onDebugReLoad...");
  }

  ///是否完成了至少一次build
  bool mIsDidBuildOnce = false;

  ///onDidBuild 之前被调用
  @mustCallSuper
  void onPreBuild() {
    vclog("onPreBuild");
  }

  ///根部组件变化之后会被执行,比如,第一次,子组件变化不会执行
  @mustCallSuper
  void onDidBuild() {
    vclog("onDidBuild");
    mIsDidBuildOnce = true;
  }

  ///被移除了显示,比如需要停止些动画什么的,deactivate被执行
  @mustCallSuper
  void onDidRemoved() {
    vclog("onDidRemoved");
  }

  ///state的dispose被执行,被释放的时候
  @mustCallSuper
  void onDispose() {
    vclog("onDispose");

    ///返回之后,直接将 _state 置空,防止继续更新
    _state = null;
  }

  void onAppLifecycleState(AppLifecycleState appState) {}

  ///是否自动保留,否则页面隐藏不显示的时候被移除了tree..,主要是tabbar的子页面
  bool wantKeepAlive = false;

  ///日志输出
  vclog(String msg) {
    log(msg);
  }
}

///基础控制器
abstract class BaseVC extends ViewCtr {
  static String mAppname = "APP_NAME";

  final Logger _logger = Logger(
      printer: PrettyPrinter(
    methodCount: 1,
    printTime: true,
  ));

  @override
  vclog(String msg) => _logger.d(msg);

  //获取控制器对应的视图
  Widget getView({Key? key}) {
    //如果是导航的根view,那么需要包裹一层导航视图,主要是最外层必须StatelessWidget,
    if (mIsNavRootVC)
      return BaseNavView(vc: this, view: BaseView(key: key, vc: this));

    //如果已经外层有了导航视图,那么这里不需要包裹导航视图了,普通页面都是这个
    return BaseView(key: key, vc: this);
  }

  ///创建顶部导航栏
  PreferredSizeWidget? makeTopBar(BuildContext context) => null;

  ///创建底部tab bar..
  Widget? makeBottomBar(BuildContext context) => null;

  ///页面的背景颜色,透明,可以制作半透明的控制器
  Color? mBackGroudColor;

  ///当前控制器是否是根控制器
  bool mIsNavRootVC = false;

  ///创建主要的控件部分,导航栏,tabbar,返回按钮,右侧按钮,标题等,底部tabbar由外部创建传入即可
  Widget realBuildWidget(BuildContext context) {
    Widget t = Scaffold(
      backgroundColor: mBackGroudColor,
      resizeToAvoidBottomInset: false,
      appBar: makeTopBar(context),
      body: wapperForExt(makePageBody(context), context),
      bottomNavigationBar: makeBottomBar(context),
    );
    var l = [t];

    t = Stack(
      children: l,
      fit: StackFit.expand,
      alignment: Alignment.center,
    );

    /// mViewHasApp 控制这个,
    /// 如果返回的是  MaterialApp 那么HUD可以全屏,否则HUD无法遮住导航栏,
    ///这里如果是完全没有导航栏的项目,返回 Scaffold ,如果有导航栏又需要全屏HUD就需要MaterialApp
    ///如果有了 MaterialApp 导航相关估计也有问题

    if (!mIsNavRootVC) return t;

    return MaterialApp(
      title: BaseVC.mAppname,
      home: t,
      theme: getThemeData(context),
      debugShowCheckedModeBanner: mShowDebugBanner,

      ///这玩意没搞懂~~,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        //奇葩问题,
        //https://blog.csdn.net/julystroy/article/details/90231588
        const FallbackCupertinoLocalisationsDelegate(),
      ],
      localeResolutionCallback: onGetLocalInfo,
      supportedLocales: getSupportedLocals(),
      navigatorObservers: getNavObservers(),
      //locale: ,先不考虑那么复杂的情况,本地这个就先不管了,遇到书写顺序有问题的再说
    );
  }

  ///监听导航变化
  List<NavigatorObserver> getNavObservers() => [];

  ///当获取到区域信息之后的回调
  Locale? onGetLocalInfo(Locale? locale, Iterable<Locale>? supportedLocales) {
    //记录当前系统的语言,和地区设置
    if (locale == null) return locale;
    mSysLang = locale.languageCode;
    if (locale.countryCode != null) mSysCountry = locale.countryCode!;
    vclog("get app local info:$locale");
    return locale;
  }

  ///支持哪些地域
  List<Locale> getSupportedLocals() => [Locale('zh'), Locale('en')];

  ///当前系统的语言,默认英语
  static String mSysLang = 'en';

  ///当前系统的地区,国家
  static String mSysCountry = 'US';

  ///获取主题数据
  ThemeData getThemeData(BuildContext context) {
    ///主题这玩意感觉太复杂了,flutter有自己的逻辑,如果设计不是这种思路,就太麻烦了
    ///比如按钮,看 button_theme.dart 源码,textcolor设置,不是简单的设置,是根据各个情况来自己设置的,
    return ThemeData(
      ///主题颜色,比如 导航栏背景 通常是最能表明一个App主题的,
      ///FloatingActionButton背景色也是这里
      primarySwatch: Colors.blue,
      //buttonColor: Colors.green,//RaisedButton的背景色,下面也可以设置
      //buttonTheme: ButtonTheme.of(context).copyWith(buttonColor: Colors.white, textTheme: ButtonTextTheme.primary),

      //textTheme: TextTheme(bodyText2: TextStyle(color: Colors.white)), //普通的text的前景色
      scaffoldBackgroundColor: Colors.white,

      ///APP的空白地方背景色
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  ///正常创建页面业务控件的地方,子类继承并且修改这个,
  ///就是之前的build方法里面创建body的部分
  Widget makePageBody(BuildContext context);

  ///是否需要键盘处理,比如有输入框,滚动视图,输入状态点击空白消失
  bool mEnableKeyBoardHelper = false;

  Widget wapperForKeyBoard(Widget body, BuildContext context) {
    return GestureDetector(
      child: SingleChildScrollView(child: body),
      onTap: () => onTapedWhenKeyBoardShow(),
    );
  }

  ///用于控制输入焦点.处理键盘
  FocusNode mFocusNode = FocusNode();
  void onTapedWhenKeyBoardShow() {
    mFocusNode.unfocus();
  }

  ///方便扩展处理,
  Widget wapperForExt(Widget body, BuildContext context) {
    if (mEnableKeyBoardHelper) return wapperForKeyBoard(body, context);
    return body;
  }

  ///页面名字,用于统计
  late String mPageName;

  ///左边返回按钮被点击之后
  void onLeftBtClicked() {}

  ///页面的返回值
  dynamic mRetVal;

  //列表相关
  List mDataArr = [];
  //当前页码
  int mPage = 0;
}

class BaseElement extends StatefulElement {
  BaseElement(StatefulWidget widget) : super(widget);

  @override
  void performRebuild() {
    Element? _old;
    visitChildren((element) {
      _old = element;
    });

    super.performRebuild();
    Element? _new;
    visitChildren((element) {
      _new = element;
    });

    if (_old != _new) {
      ///延迟35毫秒,30帧率,基本上可以保证已经渲染完了,可以直接在onDidBuild里面做些操作了
      Future.delayed(Duration(milliseconds: 35), () {
        (widget as BaseView).vc.onPreBuild();
        (widget as BaseView).vc.onDidBuild();
      });
    }
  }
}

///视图中间件...串联控制器的地方将控制器和state链接起来
// ignore: must_be_immutable
class BaseView extends StatefulWidget {
  final ViewCtr vc;
  BaseView({Key? key, required this.vc}) : super(key: key);

  @override
  State<BaseView> createState() => BaseState();
  @override
  StatefulElement createElement() => BaseElement(this);
}

///导航View,
///主要是外层需要包裹 StatelessWidget的组件..
class BaseNavView extends StatelessWidget {
  final BaseView view;
  final Key? key;
  final ViewCtr vc;
  BaseNavView({required this.vc, required this.view, this.key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: BaseVC.mAppname,
        home: view,
        debugShowCheckedModeBanner: vc.mShowDebugBanner,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ));
  }
}

///状态中间件....
class BaseState extends State<BaseView>
    with
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin,
        WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => widget.vc.wantKeepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.vc.vcBuildWidget(context, this);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    widget.vc.onInitVC();
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.vc.onDebugReLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
    widget.vc.onDispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.vc.onDidRemoved();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    widget.vc.onAppLifecycleState(state);
  }
}

///自定义的过度路由,主要是创建透明的路由页面
class CustomTransitionRoute extends PageRoute {
  CustomTransitionRoute(this.builder,
      {this.transitBuilder, RouteSettings? settings})
      : super(settings: settings);
  final WidgetBuilder builder;
  final RouteTransitionsBuilder? transitBuilder;

  @override
  Color? get barrierColor => null;

  @override
  bool get opaque => false;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return this.builder(context);
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (this.transitBuilder != null)
      return this.transitBuilder!(
          context, animation, secondaryAnimation, child);
    return FadeTransition(opacity: animation, child: child);
  }
}

//https://blog.csdn.net/julystroy/article/details/90231588
class FallbackCupertinoLocalisationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(FallbackCupertinoLocalisationsDelegate old) => false;
}
