#!/usr/bin/env dart

import 'dart:io';
import 'lib/utils/integration_verifier.dart';

/// Simple integration test runner
void main() async {
  print('🚀 Starting UI Analyzer Integration Verification...\n');

  try {
    final verifier = IntegrationVerifier();
    final report = await verifier.verifyIntegration();

    // Print detailed report
    print(report.toString());

    // Print summary
    print('📊 Summary:');
    print('Overall Score: ${report.overallScore.toStringAsFixed(1)}%');
    
    final successCount = report.results.where((r) => r.status.name == 'success').length;
    final warningCount = report.results.where((r) => r.status.name == 'warning').length;
    final failureCount = report.results.where((r) => r.status.name == 'failure').length;
    final errorCount = report.results.where((r) => r.status.name == 'error').length;
    
    print('✅ Successes: $successCount');
    print('⚠️  Warnings: $warningCount');
    print('❌ Failures: $failureCount');
    print('🔥 Errors: $errorCount');

    // Determine exit code based on results
    if (errorCount > 0 || failureCount > 0) {
      print('\n❌ Integration verification failed!');
      exit(1);
    } else if (warningCount > 0) {
      print('\n⚠️  Integration verification completed with warnings.');
      exit(0);
    } else {
      print('\n✅ Integration verification passed successfully!');
      exit(0);
    }

  } catch (e) {
    print('💥 Critical error during integration verification: $e');
    exit(1);
  }
}