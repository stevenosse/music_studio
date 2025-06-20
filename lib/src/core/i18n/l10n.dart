// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class I18n {
  I18n();

  static I18n? _current;

  static I18n get current {
    assert(
      _current != null,
      'No instance of I18n was loaded. Try to initialize the I18n delegate before accessing I18n.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<I18n> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = I18n();
      I18n._current = instance;

      return instance;
    });
  }

  static I18n of(BuildContext context) {
    final instance = I18n.maybeOf(context);
    assert(
      instance != null,
      'No instance of I18n present in the widget tree. Did you add I18n.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static I18n? maybeOf(BuildContext context) {
    return Localizations.of<I18n>(context, I18n);
  }

  /// `Login`
  String get login_title {
    return Intl.message('Login', name: 'login_title', desc: '', args: []);
  }

  /// `Let's continue where we left off.`
  String get login_subtitle {
    return Intl.message(
      'Let\'s continue where we left off.',
      name: 'login_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get login_emailLabel {
    return Intl.message('Email', name: 'login_emailLabel', desc: '', args: []);
  }

  /// `Ex: KpNqg@example.com`
  String get login_emailHint {
    return Intl.message(
      'Ex: KpNqg@example.com',
      name: 'login_emailHint',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get login_passwordLabel {
    return Intl.message(
      'Password',
      name: 'login_passwordLabel',
      desc: '',
      args: [],
    );
  }

  /// `************`
  String get login_passwordHint {
    return Intl.message(
      '************',
      name: 'login_passwordHint',
      desc: '',
      args: [],
    );
  }

  /// `Forgot password?`
  String get login_forgotPasswordLabel {
    return Intl.message(
      'Forgot password?',
      name: 'login_forgotPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Google`
  String get login_googleBtnLabel {
    return Intl.message(
      'Sign in with Google',
      name: 'login_googleBtnLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Apple`
  String get login_appleBtnLabel {
    return Intl.message(
      'Sign in with Apple',
      name: 'login_appleBtnLabel',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login_submitBtnLabel {
    return Intl.message(
      'Login',
      name: 'login_submitBtnLabel',
      desc: '',
      args: [],
    );
  }

  /// `Please wait...`
  String get loadingDialog_content {
    return Intl.message(
      'Please wait...',
      name: 'loadingDialog_content',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get dialog_cancel {
    return Intl.message('Cancel', name: 'dialog_cancel', desc: '', args: []);
  }

  /// `Confirm`
  String get dialog_confirm {
    return Intl.message('Confirm', name: 'dialog_confirm', desc: '', args: []);
  }

  /// `OR`
  String get or {
    return Intl.message('OR', name: 'or', desc: '', args: []);
  }

  /// `Piano Roll`
  String get pianoRoll_title {
    return Intl.message(
      'Piano Roll',
      name: 'pianoRoll_title',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get pianoRoll_play {
    return Intl.message('Play', name: 'pianoRoll_play', desc: '', args: []);
  }

  /// `Pause`
  String get pianoRoll_pause {
    return Intl.message('Pause', name: 'pianoRoll_pause', desc: '', args: []);
  }

  /// `Stop`
  String get pianoRoll_stop {
    return Intl.message('Stop', name: 'pianoRoll_stop', desc: '', args: []);
  }

  /// `Zoom In`
  String get pianoRoll_zoomIn {
    return Intl.message(
      'Zoom In',
      name: 'pianoRoll_zoomIn',
      desc: '',
      args: [],
    );
  }

  /// `Zoom Out`
  String get pianoRoll_zoomOut {
    return Intl.message(
      'Zoom Out',
      name: 'pianoRoll_zoomOut',
      desc: '',
      args: [],
    );
  }

  /// `Snap to Grid`
  String get pianoRoll_snapToGrid {
    return Intl.message(
      'Snap to Grid',
      name: 'pianoRoll_snapToGrid',
      desc: '',
      args: [],
    );
  }

  /// `Draw Mode`
  String get pianoRoll_drawMode {
    return Intl.message(
      'Draw Mode',
      name: 'pianoRoll_drawMode',
      desc: '',
      args: [],
    );
  }

  /// `Select Mode`
  String get pianoRoll_selectMode {
    return Intl.message(
      'Select Mode',
      name: 'pianoRoll_selectMode',
      desc: '',
      args: [],
    );
  }

  /// `Quantize`
  String get pianoRoll_quantize {
    return Intl.message(
      'Quantize',
      name: 'pianoRoll_quantize',
      desc: '',
      args: [],
    );
  }

  /// `Velocity`
  String get pianoRoll_velocity {
    return Intl.message(
      'Velocity',
      name: 'pianoRoll_velocity',
      desc: '',
      args: [],
    );
  }

  /// `Delete Note`
  String get pianoRoll_deleteNote {
    return Intl.message(
      'Delete Note',
      name: 'pianoRoll_deleteNote',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate Note`
  String get pianoRoll_duplicateNote {
    return Intl.message(
      'Duplicate Note',
      name: 'pianoRoll_duplicateNote',
      desc: '',
      args: [],
    );
  }

  /// `Select All`
  String get pianoRoll_selectAll {
    return Intl.message(
      'Select All',
      name: 'pianoRoll_selectAll',
      desc: '',
      args: [],
    );
  }

  /// `Deselect All`
  String get pianoRoll_deselectAll {
    return Intl.message(
      'Deselect All',
      name: 'pianoRoll_deselectAll',
      desc: '',
      args: [],
    );
  }

  /// `Ghost Notes`
  String get pianoRoll_ghostNotes {
    return Intl.message(
      'Ghost Notes',
      name: 'pianoRoll_ghostNotes',
      desc: '',
      args: [],
    );
  }

  /// `Legato`
  String get pianoRoll_legato {
    return Intl.message('Legato', name: 'pianoRoll_legato', desc: '', args: []);
  }

  /// `Note Properties`
  String get pianoRoll_noteProperties {
    return Intl.message(
      'Note Properties',
      name: 'pianoRoll_noteProperties',
      desc: '',
      args: [],
    );
  }

  /// `Pitch`
  String get pianoRoll_pitch {
    return Intl.message('Pitch', name: 'pianoRoll_pitch', desc: '', args: []);
  }

  /// `Start Time`
  String get pianoRoll_startTime {
    return Intl.message(
      'Start Time',
      name: 'pianoRoll_startTime',
      desc: '',
      args: [],
    );
  }

  /// `Duration`
  String get pianoRoll_duration {
    return Intl.message(
      'Duration',
      name: 'pianoRoll_duration',
      desc: '',
      args: [],
    );
  }

  /// `Channel`
  String get pianoRoll_channel {
    return Intl.message(
      'Channel',
      name: 'pianoRoll_channel',
      desc: '',
      args: [],
    );
  }

  /// `1/4`
  String get pianoRoll_resolution_quarter {
    return Intl.message(
      '1/4',
      name: 'pianoRoll_resolution_quarter',
      desc: '',
      args: [],
    );
  }

  /// `1/8`
  String get pianoRoll_resolution_eighth {
    return Intl.message(
      '1/8',
      name: 'pianoRoll_resolution_eighth',
      desc: '',
      args: [],
    );
  }

  /// `1/16`
  String get pianoRoll_resolution_sixteenth {
    return Intl.message(
      '1/16',
      name: 'pianoRoll_resolution_sixteenth',
      desc: '',
      args: [],
    );
  }

  /// `1/32`
  String get pianoRoll_resolution_thirtysecond {
    return Intl.message(
      '1/32',
      name: 'pianoRoll_resolution_thirtysecond',
      desc: '',
      args: [],
    );
  }

  /// `Triplets`
  String get pianoRoll_resolution_triplets {
    return Intl.message(
      'Triplets',
      name: 'pianoRoll_resolution_triplets',
      desc: '',
      args: [],
    );
  }

  /// `None`
  String get pianoRoll_resolution_none {
    return Intl.message(
      'None',
      name: 'pianoRoll_resolution_none',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<I18n> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<I18n> load(Locale locale) => I18n.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
