// private 값들은 불러올 수 없다.
import 'dart:io';

import 'package:calendar_scheduler/model/category_colors.dart';
import 'package:calendar_scheduler/model/schedule_with_color.dart';
import 'package:calendar_scheduler/model/schedules.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';

// private 값까지 불러올 수 있다.
part 'drift_database.g.dart';

@DriftDatabase(
  tables: [
    Schedules,
    CategoryColors,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  Future<Schedule> getScheduleById(int id) =>
      (select(schedules)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<int> createSchedule(SchedulesCompanion data) =>
      into(schedules).insert(data);

  Future<int> createCategoryColor(CategoryColorsCompanion data) =>
      into(categoryColors).insert(data);

  Future<List<CategoryColor>> getCategoryColors() =>
      select(categoryColors).get();

  Future<int> updateScheduleById(int id, SchedulesCompanion data) =>
      (update(schedules)..where((tbl) => tbl.id.equals(id))).write(data);

  Future<int> removeSchedule(int id) =>
      (delete(schedules)..where((tbl) => tbl.id.equals(id))).go();

  // Stream<List<Schedule>> watchSchedules(DateTime date) =>
  //     (select(schedules)..where((tbl) => tbl.date.equals(date))).watch();

  // Stream<List<Schedule>> watchSchedules(DateTime date) {
  //   // final query = select(schedules);
  //   // query.where((tbl) => tbl.date.equals(date));
  //   // return query.watch();
  //
  //   // // ..
  //   // int number = 3;
  //   // // '3' -> String
  //   // final resp = number.toString();
  //   // // 3 -> int   // toString 으로 변환은 되나 type 은 number 의 타입을 가져옴
  //   // final resp2 = number..toString();
  //
  //   return (select(schedules)..where((tbl) => tbl.date.equals(date))).watch();
  // }

  Stream<List<ScheduleWithColor>> watchSchedules(DateTime date) {
    final query = select(schedules).join([
      innerJoin(categoryColors, categoryColors.id.equalsExp(schedules.colorId))
    ]);

    query.where(schedules.date.equals(date));
    query.orderBy(
        [
          // asc - ascending // desc - descending
          OrderingTerm.asc(schedules.startTime),
        ],
    );

    return query.watch().map(
          (rows) => rows.map(
            (row) => ScheduleWithColor(
              schedule: row.readTable(schedules),
              categoryColor: row.readTable(categoryColors),
            ),
          ).toList(),
        );
  }

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
