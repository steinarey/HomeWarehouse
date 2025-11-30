import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Home Warehouse',
      'home': 'Home',
      'useRestock': 'Scan',
      'lowStock': 'Low Stock',
      'activity': 'Activity',
      'settings': 'Settings',
      'login': 'Login',
      'username': 'Username',
      'password': 'Password',
      'createAccount': 'Create Account',
      'logout': 'Logout',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'english': 'English',
      'icelandic': 'Icelandic',
      'required': 'Required',
      'passwordsDoNotMatch': 'Passwords do not match',
      'confirmPassword': 'Confirm Password',
      'scan': 'Scan',
      'search': 'Search',
      'categories': 'Categories',
      'addCategory': 'Add Category',
      'editCategory': 'Edit Category',
      'deleteCategory': 'Delete Category',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'confirmDelete': 'Are you sure you want to delete this?',
      'undo': 'Undo',
      'actionUndone': 'Action undone successfully',
      'error': 'Error',
      'loading': 'Loading...',
      'noData': 'No data available',
      'recentActivity': 'Recent Activity',
      'dashboard': 'Dashboard',
      'totalProducts': 'Total Products',
      'totalStock': 'Total Stock',
      'lowStockItems': 'Low Stock Items',
      'totalValue': 'Total Value',
      'connection': 'Connection',
      'backendUrl': 'Backend URL',
      'saveUrl': 'Save URL',
      'activeUser': 'Active User',
      'currentUser': 'Current User',
      'appInfo': 'App Info',
      'version': 'Version',
    },
    'is': {
      'appTitle': 'Heimavöruhús',
      'home': 'Heim',
      'useRestock': 'Skanna',
      'lowStock': 'Lítil birgða',
      'activity': 'Virkni',
      'settings': 'Stillingar',
      'login': 'Innskráning',
      'username': 'Notendanafn',
      'password': 'Lykilorð',
      'createAccount': 'Búa til aðgang',
      'logout': 'Útskrá',
      'darkMode': 'Dökkur hamur',
      'language': 'Tungumál',
      'system': 'Kerfi',
      'light': 'Ljós',
      'dark': 'Dökkur',
      'english': 'Enska',
      'icelandic': 'Íslenska',
      'required': 'Nauðsynlegt',
      'passwordsDoNotMatch': 'Lykilorð passa ekki saman',
      'confirmPassword': 'Staðfesta lykilorð',
      'scan': 'Skanna',
      'search': 'Leita',
      'categories': 'Vöruflokkar',
      'addCategory': 'Bæta við flokki',
      'editCategory': 'Breyta flokki',
      'deleteCategory': 'Eyða flokki',
      'cancel': 'Hætta við',
      'save': 'Vista',
      'delete': 'Eyða',
      'confirmDelete': 'Ertu viss um að þú viljir eyða þessu?',
      'undo': 'Afturkalla',
      'actionUndone': 'Aðgerð afturkölluð',
      'error': 'Villa',
      'loading': 'Hleður...',
      'noData': 'Engin gögn',
      'recentActivity': 'Nýleg virkni',
      'dashboard': 'Yfirlit',
      'totalProducts': 'Allar vörur',
      'totalStock': 'Heildarbirgðir',
      'lowStockItems': 'Vörur sem vantar',
      'totalValue': 'Heildarverðmæti',
      'connection': 'Tenging',
      'backendUrl': 'Vefslóð bakenda',
      'saveUrl': 'Vista slóð',
      'activeUser': 'Virkur notandi',
      'currentUser': 'Núverandi notandi',
      'appInfo': 'Upplýsingar um app',
      'version': 'Útgáfa',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'is'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
