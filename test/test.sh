#!/bin/bash

DIR="$( dirname "$_" )"
dart $DIR"/unit.dart" &&
dart $DIR"/run.dart" &&
dart $DIR"/compile.files.dart" &&
dart $DIR"/jade.test.dart"