import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The palette. One green family carries the whole app: a deep forest for
/// chrome, a mint for paper, and a single bright green for anything tappable.
/// Gold marks rank and streaks; red marks anything that needs the field worker
/// to act today.
class Iro {
  // Greens, darkest to lightest.
  static const forest = Color(0xFF0C3320);
  static const deep = Color(0xFF114A2C);
  static const green = Color(0xFF15633A);
  static const greenMid = Color(0xFF1C7D48);
  static const bright = Color(0xFF22A75D);
  static const leaf = Color(0xFF40C078);

  // Washes — card fills and chip backgrounds.
  static const wash = Color(0xFFDCF0E3);
  static const wash2 = Color(0xFFEDF7F0);
  static const mint = Color(0xFFE9F4EC);

  // Gold, for rank, streaks and anything earned.
  static const gold = Color(0xFFC79417);
  static const goldBright = Color(0xFFF2C14E);
  static const goldWash = Color(0xFFFBF1D6);

  // Signals.
  static const alert = Color(0xFFBF3B2B);
  static const alertWash = Color(0xFFFBE8E4);
  static const sky = Color(0xFF1C6EA4);
  static const skyWash = Color(0xFFE3EFF7);

  // Ink and rules.
  static const ink = Color(0xFF10291C);
  static const ink2 = Color(0xFF3B5648);
  static const muted = Color(0xFF6D8579);
  static const muted2 = Color(0xFF9CB0A4);
  static const line = Color(0xFFDBEADF);
  static const surface = Color(0xFFFFFFFF);
  static const onDark = Color(0xFFD6EFDF);

  /// The header pill and every dark band under it.
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forest, deep, green],
  );

  /// The one call-to-action fill.
  static const actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenMid, bright],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldBright, gold],
  );
}

/// Card elevation for the IRO kit. Two layers: a tight contact shadow and a
/// wide soft one, so cards lift off the mint without looking heavy.
const iroCardShadow = [
  BoxShadow(color: Color(0x0F0C3320), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x140C3320), blurRadius: 18, offset: Offset(0, 8)),
];

class AppColors {
  /// Sign-in and OTP only, deliberately left out of the green retint so the two
  /// screens over `login_bg.jpg` look as they did.
  static const loginNavy = Color(0xFF1C0F4A);
  static const brand = Iro.green;
  static const brandLight = Iro.greenMid;
  static const brandWash = Iro.wash;
  static const brandOn = Color(0xFFFFFFFF);
  static const accent = Iro.bright;
  static const ok = Iro.greenMid;
  static const okBg = Iro.wash;
  static const warn = Iro.gold;
  static const warnBg = Iro.goldWash;
  static const bad = Iro.alert;
  static const badBg = Iro.alertWash;
  static const ink = Iro.ink;
  static const ink2 = Iro.ink2;
  static const ink3 = Iro.muted;
  static const ink4 = Iro.muted2;

  /// Page background. Mint paper, with cards in white on top of it.
  static const paper = Iro.mint;
  static const card = Iro.surface;
  static const card2 = Iro.wash2;
  static const sunk = Iro.wash2;
  static const rule = Iro.line;
  static const rule2 = Color(0xFFBFD6C7);
}

class VerifyColors {
  static const deep = Iro.forest;
  static const purple = Iro.green;
  static const soft = Iro.greenMid;
  static const pale = Iro.wash2;
  static const orange = Iro.bright;
  static const orangeSoft = Iro.leaf;
  static const navyDeep = Iro.forest;
  static const cream = Iro.wash2;
  static const ink = Iro.ink;
  static const gray = Iro.muted;
  static const line = Iro.line;
}

/// Kept under the old names so every screen in the app picks up the green
/// without a rename. `navy` is now the forest green, `orange` is the action
/// green, and `peach` is the light wash behind placeholder art.
class HomeColors {
  static const navy = Iro.forest;
  static const navyDeep = Iro.forest;
  static const navyMid = Iro.deep;
  static const navyLine = Color(0x80FFFFFF);
  static const navyMuted = Iro.onDark;
  static const ink = Iro.ink;
  static const muted = Iro.muted;
  static const muted2 = Iro.muted2;
  static const paper = Iro.mint;
  static const surface = Iro.surface;
  static const orange = Iro.bright;
  static const orangeSoft = Iro.leaf;
  static const orangeDark = Iro.greenMid;
  static const orangeDeep = Iro.green;
  static const peach = Iro.wash;
  static const peach2 = Iro.wash2;
  static const taskBg = Iro.goldWash;
  static const taskLine = Iro.gold;
  static const lastBg = Iro.surface;
  static const lastText = Iro.muted;
  static const border = Iro.line;
  static const fab = Iro.green;
  static const navActive = Iro.green;
  static const navBar = Iro.surface;

  /// The avatar disc and the initials drawn on it.
  static const accent300 = Iro.wash;
  static const accent900 = Iro.green;

  static const teal = Iro.greenMid;
  static const tealMid = Iro.leaf;
  static const tealWash = Iro.wash;

  /// Deep green for text sitting on [tealWash].
  static const tealInk = Iro.ink;
  static const tealMuted = Iro.muted;

  /// Hairline drawn from the same family as the app bar.
  static const mintLine = Iro.line;
}

/// The field every app bar paints: forest green running lighter across it.
const appBarGradient = Iro.headerGradient;

/// Status bar chrome matching the top of [appBarGradient] — light icons on the
/// forest green.
const appBarOverlay = SystemUiOverlayStyle(
  statusBarColor: Iro.forest,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

/// Pass as `AppBar.flexibleSpace` to paint [appBarGradient] behind a plain bar;
/// AppBarTheme carries a colour but not a gradient, so each bar needs this.
const appBarGradientSpace = DecoratedBox(
  decoration: BoxDecoration(
    gradient: appBarGradient,
    border: Border(bottom: BorderSide(color: Iro.forest)),
  ),
  // AppBar stacks flexibleSpace under loose constraints, and a childless
  // DecoratedBox takes constraints.smallest — it would paint nothing.
  child: SizedBox.expand(),
);

/// Card elevation on the home page: two tight layers close to the surface, so
/// a card reads as lifted rather than sitting under a wide diffuse halo.
const homeCardShadow = [
  BoxShadow(color: Color(0x0A0C3320), blurRadius: 1, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x140C3320), blurRadius: 4, offset: Offset(0, 2)),
];

class AppSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const screen = 18.0;
  static const cardRadius = 24.0;
  static const controlRadius = 16.0;
  static const sheetRadius = 28.0;
}
