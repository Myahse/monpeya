import 'package:flutter/material.dart';

import 'service_scaffold.dart';

class MrImmoRentalScreen extends StatelessWidget {
  const MrImmoRentalScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return ServiceScaffold(
      title: 'Mr Immo Rental',
      child: Text('Mr Immo Rental moduleId=$moduleId (placeholder)'),
    );
  }
}

class MrImmoConstructionScreen extends StatelessWidget {
  const MrImmoConstructionScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return ServiceScaffold(
      title: 'Mr Immo Construction',
      child: Text('Mr Immo Construction moduleId=$moduleId (placeholder)'),
    );
  }
}

class MrImmoCollectionScreen extends StatelessWidget {
  const MrImmoCollectionScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return ServiceScaffold(
      title: 'Mr Immo Collection',
      child: Text('Mr Immo Collection moduleId=$moduleId (placeholder)'),
    );
  }
}

