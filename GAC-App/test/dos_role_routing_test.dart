import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/login.dart';
import 'package:gac_flutter/models/authenticated_user.dart';

void main() {
  const dosRoles = <String, String>{
    'SM': 'SALES MANAGER',
    'DOS_SALES': 'SALES MANAGER',
    'ASM': 'ASM',
    'CE': 'CE SERVICE',
    'PARTS': 'PARTS',
    'JC': 'JC',
    'WS SUP': 'WS SUP',
  };

  group('DOS login routing', () {
    test('routes all non-admin DOS roles to the DOS dashboard', () {
      for (final role in dosRoles.keys) {
        expect(
          destinationForUserType(role),
          '/(dos)/dashboard',
          reason: '$role must enter the DOS user shell',
        );
      }
    });

    test('keeps PIC and administrator destinations separate', () {
      expect(destinationForUserType('PIC'), '/(user)/home');
      expect(destinationForUserType('ADMIN'), '/(admin)/dashboard');
    });
  });

  group('DOS role policy', () {
    test('recognizes every listed account role and checker code', () {
      var id = 1;
      for (final entry in dosRoles.entries) {
        final user = AuthenticatedUser(
          id: id++,
          name: entry.key,
          email: '${entry.key.toLowerCase().replaceAll(' ', '.')}@gateway.com',
          userType: entry.key,
          accountStatus: 'active',
        );

        expect(user.isDosAuditor, isTrue, reason: '${entry.key} is a DOS user');
        expect(user.isAdmin, isFalse, reason: '${entry.key} is not an admin');
        expect(
          user.dosCheckerCode,
          entry.value,
          reason: '${entry.key} must see only its DOS checker scope',
        );
      }
    });

    test('normalizes common Parts and Workshop Supervisor variants', () {
      const aliases = <String, String>{
        'Parts Supervisor': 'PARTS',
        'PARTS_SUPERVISOR': 'PARTS',
        'WS_SUP': 'WS SUP',
        'WS.SUP': 'WS SUP',
        'Workshop Supervisor': 'WS SUP',
        'Worshop Sup': 'WS SUP',
        'WORKSHOPSUPERVISOR': 'WS SUP',
        'WORKSHOPSUP': 'WS SUP',
      };

      var id = 100;
      for (final entry in aliases.entries) {
        final user = AuthenticatedUser(
          id: id++,
          name: entry.key,
          email: 'role$id@gateway.com',
          userType: entry.key,
          accountStatus: 'active',
        );
        expect(user.isDosAuditor, isTrue, reason: entry.key);
        expect(user.dosCheckerCode, entry.value, reason: entry.key);
      }
    });

    test('normalizes legacy standalone workshop aliases to WS SUP', () {
      for (final legacyType in const ['WS', 'WORKSHOP']) {
        final user = AuthenticatedUser.fromJson({
          'id': 150,
          'name': 'Workshop Supervisor',
          'email': 'workshop.supervisor@gateway.com',
          'user_type': legacyType,
          'account_status': 'active',
        });

        expect(user.userType, 'WS SUP', reason: legacyType);
        expect(user.canonicalUserType, 'WS SUP', reason: legacyType);
        expect(user.roleLabel, 'Workshop Supervisor', reason: legacyType);
        expect(user.dosCheckerCode, 'WS SUP', reason: legacyType);
        expect(user.matchesCheckerRole(legacyType), isTrue, reason: legacyType);
        expect(user.toJson()['user_type'], 'WS SUP', reason: legacyType);
        expect(
          destinationForUserType(legacyType),
          '/(dos)/dashboard',
          reason: legacyType,
        );
      }
    });

    test('recognizes dedicated DOS Sales and Aftersales account aliases', () {
      const sales = AuthenticatedUser(
        id: 300,
        name: 'DOS Sales',
        email: 'dos.sales@gateway.com',
        userType: 'DOS_SALES',
        accountStatus: 'active',
      );
      const aftersales = AuthenticatedUser(
        id: 301,
        name: 'DOS Aftersales',
        email: 'dos.aftersales@gateway.com',
        userType: 'DOS_AFTERSALES',
        accountStatus: 'active',
      );

      expect(sales.isDosAuditor, isTrue);
      expect(sales.isDosSales, isTrue);
      expect(sales.dosCheckerCode, 'SALES MANAGER');
      expect(sales.matchesCheckerRole('SALES MANAGER'), isTrue);
      expect(sales.canSwitchDosTracks, isFalse);

      expect(aftersales.isDosAuditor, isTrue);
      expect(aftersales.isDosAftersales, isTrue);
      expect(aftersales.dosCheckerCode, isNull);
      expect(aftersales.matchesCheckerRole('ASM'), isTrue);
      expect(aftersales.matchesCheckerRole('CE SERVICE'), isTrue);
      expect(aftersales.canSwitchDosTracks, isFalse);
    });

    test('Workshop Supervisor does not match Parts Supervisor items', () {
      const user = AuthenticatedUser(
        id: 200,
        name: 'Workshop Supervisor',
        email: 'ws.sup@gateway.com',
        userType: 'WORKSHOP SUP',
        accountStatus: 'active',
      );

      expect(user.matchesCheckerRole('WORKSHOP SUP'), isTrue);
      expect(user.matchesCheckerRole('WORSHOP SUP'), isTrue);
      expect(user.matchesCheckerRole('WS SUP'), isTrue);
      expect(user.matchesCheckerRole('Parts Supervisor'), isFalse);
      expect(user.matchesCheckerRole('PARTS'), isFalse);
    });
  });
}
