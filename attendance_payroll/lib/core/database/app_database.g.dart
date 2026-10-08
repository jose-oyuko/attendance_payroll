// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CompaniesTable extends Companies
    with TableInfo<$CompaniesTable, CompanyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompaniesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($CompaniesTable.$convertersyncState);
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legalNameMeta = const VerificationMeta(
    'legalName',
  );
  @override
  late final GeneratedColumn<String> legalName = GeneratedColumn<String>(
    'legal_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registrationNumberMeta =
      const VerificationMeta('registrationNumber');
  @override
  late final GeneratedColumn<String> registrationNumber =
      GeneratedColumn<String>(
        'registration_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    name,
    legalName,
    registrationNumber,
    phone,
    email,
    address,
    currencyCode,
    timezone,
    logoPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'companies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompanyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('legal_name')) {
      context.handle(
        _legalNameMeta,
        legalName.isAcceptableOrUnknown(data['legal_name']!, _legalNameMeta),
      );
    }
    if (data.containsKey('registration_number')) {
      context.handle(
        _registrationNumberMeta,
        registrationNumber.isAcceptableOrUnknown(
          data['registration_number']!,
          _registrationNumberMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompanyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompanyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncState: $CompaniesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      legalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal_name'],
      ),
      registrationNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_number'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
    );
  }

  @override
  $CompaniesTable createAlias(String alias) {
    return $CompaniesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class CompanyRow extends DataClass implements Insertable<CompanyRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final SyncState syncState;
  final DateTime? deletedAt;
  final String name;
  final String? legalName;
  final String? registrationNumber;
  final String? phone;
  final String? email;
  final String? address;

  /// ISO 4217 code, for example `KES`.
  final String currencyCode;

  /// IANA timezone name, for example `Africa/Nairobi`.
  final String timezone;
  final String? logoPath;
  const CompanyRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncState,
    this.deletedAt,
    required this.name,
    this.legalName,
    this.registrationNumber,
    this.phone,
    this.email,
    this.address,
    required this.currencyCode,
    required this.timezone,
    this.logoPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    {
      map['sync_state'] = Variable<String>(
        $CompaniesTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || legalName != null) {
      map['legal_name'] = Variable<String>(legalName);
    }
    if (!nullToAbsent || registrationNumber != null) {
      map['registration_number'] = Variable<String>(registrationNumber);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['timezone'] = Variable<String>(timezone);
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    return map;
  }

  CompaniesCompanion toCompanion(bool nullToAbsent) {
    return CompaniesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      syncState: Value(syncState),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      legalName: legalName == null && nullToAbsent
          ? const Value.absent()
          : Value(legalName),
      registrationNumber: registrationNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(registrationNumber),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      currencyCode: Value(currencyCode),
      timezone: Value(timezone),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
    );
  }

  factory CompanyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompanyRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      syncState: $CompaniesTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      legalName: serializer.fromJson<String?>(json['legalName']),
      registrationNumber: serializer.fromJson<String?>(
        json['registrationNumber'],
      ),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      timezone: serializer.fromJson<String>(json['timezone']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'syncState': serializer.toJson<String>(
        $CompaniesTable.$convertersyncState.toJson(syncState),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'legalName': serializer.toJson<String?>(legalName),
      'registrationNumber': serializer.toJson<String?>(registrationNumber),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'timezone': serializer.toJson<String>(timezone),
      'logoPath': serializer.toJson<String?>(logoPath),
    };
  }

  CompanyRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    SyncState? syncState,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    Value<String?> legalName = const Value.absent(),
    Value<String?> registrationNumber = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> address = const Value.absent(),
    String? currencyCode,
    String? timezone,
    Value<String?> logoPath = const Value.absent(),
  }) => CompanyRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    syncState: syncState ?? this.syncState,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    legalName: legalName.present ? legalName.value : this.legalName,
    registrationNumber: registrationNumber.present
        ? registrationNumber.value
        : this.registrationNumber,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    address: address.present ? address.value : this.address,
    currencyCode: currencyCode ?? this.currencyCode,
    timezone: timezone ?? this.timezone,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
  );
  CompanyRow copyWithCompanion(CompaniesCompanion data) {
    return CompanyRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      legalName: data.legalName.present ? data.legalName.value : this.legalName,
      registrationNumber: data.registrationNumber.present
          ? data.registrationNumber.value
          : this.registrationNumber,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompanyRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('legalName: $legalName, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('timezone: $timezone, ')
          ..write('logoPath: $logoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    name,
    legalName,
    registrationNumber,
    phone,
    email,
    address,
    currencyCode,
    timezone,
    logoPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompanyRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.syncState == this.syncState &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.legalName == this.legalName &&
          other.registrationNumber == this.registrationNumber &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.currencyCode == this.currencyCode &&
          other.timezone == this.timezone &&
          other.logoPath == this.logoPath);
}

class CompaniesCompanion extends UpdateCompanion<CompanyRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<SyncState> syncState;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String?> legalName;
  final Value<String?> registrationNumber;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String> currencyCode;
  final Value<String> timezone;
  final Value<String?> logoPath;
  final Value<int> rowid;
  const CompaniesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.legalName = const Value.absent(),
    this.registrationNumber = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.timezone = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompaniesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String name,
    this.legalName = const Value.absent(),
    this.registrationNumber = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    required String currencyCode,
    required String timezone,
    this.logoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       currencyCode = Value(currencyCode),
       timezone = Value(timezone);
  static Insertable<CompanyRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<String>? syncState,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? legalName,
    Expression<String>? registrationNumber,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? currencyCode,
    Expression<String>? timezone,
    Expression<String>? logoPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (syncState != null) 'sync_state': syncState,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (legalName != null) 'legal_name': legalName,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (timezone != null) 'timezone': timezone,
      if (logoPath != null) 'logo_path': logoPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompaniesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<SyncState>? syncState,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String?>? legalName,
    Value<String?>? registrationNumber,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? address,
    Value<String>? currencyCode,
    Value<String>? timezone,
    Value<String?>? logoPath,
    Value<int>? rowid,
  }) {
    return CompaniesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      currencyCode: currencyCode ?? this.currencyCode,
      timezone: timezone ?? this.timezone,
      logoPath: logoPath ?? this.logoPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $CompaniesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (legalName.present) {
      map['legal_name'] = Variable<String>(legalName.value);
    }
    if (registrationNumber.present) {
      map['registration_number'] = Variable<String>(registrationNumber.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompaniesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('legalName: $legalName, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('timezone: $timezone, ')
          ..write('logoPath: $logoPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdminUsersTable extends AdminUsers
    with TableInfo<$AdminUsersTable, AdminUserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdminUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($AdminUsersTable.$convertersyncState);
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES companies (id)',
    ),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastLoginAtMeta = const VerificationMeta(
    'lastLoginAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
    'last_login_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    companyId,
    username,
    displayName,
    role,
    active,
    lastLoginAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'admin_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdminUserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
        _lastLoginAtMeta,
        lastLoginAt.isAcceptableOrUnknown(
          data['last_login_at']!,
          _lastLoginAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {companyId, username},
  ];
  @override
  AdminUserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdminUserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncState: $AdminUsersTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      lastLoginAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_login_at'],
      ),
    );
  }

  @override
  $AdminUsersTable createAlias(String alias) {
    return $AdminUsersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class AdminUserRow extends DataClass implements Insertable<AdminUserRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final SyncState syncState;
  final DateTime? deletedAt;
  final String companyId;

  /// Normalised (trimmed, lower-case) login name.
  final String username;
  final String displayName;
  final String role;
  final bool active;
  final DateTime? lastLoginAt;
  const AdminUserRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncState,
    this.deletedAt,
    required this.companyId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.active,
    this.lastLoginAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    {
      map['sync_state'] = Variable<String>(
        $AdminUsersTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['company_id'] = Variable<String>(companyId);
    map['username'] = Variable<String>(username);
    map['display_name'] = Variable<String>(displayName);
    map['role'] = Variable<String>(role);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    }
    return map;
  }

  AdminUsersCompanion toCompanion(bool nullToAbsent) {
    return AdminUsersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      syncState: Value(syncState),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      companyId: Value(companyId),
      username: Value(username),
      displayName: Value(displayName),
      role: Value(role),
      active: Value(active),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
    );
  }

  factory AdminUserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdminUserRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      syncState: $AdminUsersTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      companyId: serializer.fromJson<String>(json['companyId']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      active: serializer.fromJson<bool>(json['active']),
      lastLoginAt: serializer.fromJson<DateTime?>(json['lastLoginAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'syncState': serializer.toJson<String>(
        $AdminUsersTable.$convertersyncState.toJson(syncState),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'companyId': serializer.toJson<String>(companyId),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(role),
      'active': serializer.toJson<bool>(active),
      'lastLoginAt': serializer.toJson<DateTime?>(lastLoginAt),
    };
  }

  AdminUserRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    SyncState? syncState,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? companyId,
    String? username,
    String? displayName,
    String? role,
    bool? active,
    Value<DateTime?> lastLoginAt = const Value.absent(),
  }) => AdminUserRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    syncState: syncState ?? this.syncState,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    companyId: companyId ?? this.companyId,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    active: active ?? this.active,
    lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
  );
  AdminUserRow copyWithCompanion(AdminUsersCompanion data) {
    return AdminUserRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      username: data.username.present ? data.username.value : this.username,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      active: data.active.present ? data.active.value : this.active,
      lastLoginAt: data.lastLoginAt.present
          ? data.lastLoginAt.value
          : this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdminUserRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('companyId: $companyId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('active: $active, ')
          ..write('lastLoginAt: $lastLoginAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    companyId,
    username,
    displayName,
    role,
    active,
    lastLoginAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminUserRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.syncState == this.syncState &&
          other.deletedAt == this.deletedAt &&
          other.companyId == this.companyId &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.active == this.active &&
          other.lastLoginAt == this.lastLoginAt);
}

class AdminUsersCompanion extends UpdateCompanion<AdminUserRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<SyncState> syncState;
  final Value<DateTime?> deletedAt;
  final Value<String> companyId;
  final Value<String> username;
  final Value<String> displayName;
  final Value<String> role;
  final Value<bool> active;
  final Value<DateTime?> lastLoginAt;
  final Value<int> rowid;
  const AdminUsersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.companyId = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.active = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdminUsersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String companyId,
    required String username,
    required String displayName,
    required String role,
    this.active = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       companyId = Value(companyId),
       username = Value(username),
       displayName = Value(displayName),
       role = Value(role);
  static Insertable<AdminUserRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<String>? syncState,
    Expression<DateTime>? deletedAt,
    Expression<String>? companyId,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<bool>? active,
    Expression<DateTime>? lastLoginAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (syncState != null) 'sync_state': syncState,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (companyId != null) 'company_id': companyId,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (active != null) 'active': active,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdminUsersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<SyncState>? syncState,
    Value<DateTime?>? deletedAt,
    Value<String>? companyId,
    Value<String>? username,
    Value<String>? displayName,
    Value<String>? role,
    Value<bool>? active,
    Value<DateTime?>? lastLoginAt,
    Value<int>? rowid,
  }) {
    return AdminUsersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      deletedAt: deletedAt ?? this.deletedAt,
      companyId: companyId ?? this.companyId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      active: active ?? this.active,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $AdminUsersTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdminUsersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('companyId: $companyId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('active: $active, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmployeesTable extends Employees
    with TableInfo<$EmployeesTable, EmployeeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($EmployeesTable.$convertersyncState);
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES companies (id)',
    ),
  );
  static const VerificationMeta _employeeNumberMeta = const VerificationMeta(
    'employeeNumber',
  );
  @override
  late final GeneratedColumn<String> employeeNumber = GeneratedColumn<String>(
    'employee_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _middleNameMeta = const VerificationMeta(
    'middleName',
  );
  @override
  late final GeneratedColumn<String> middleName = GeneratedColumn<String>(
    'middle_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobTitleMeta = const VerificationMeta(
    'jobTitle',
  );
  @override
  late final GeneratedColumn<String> jobTitle = GeneratedColumn<String>(
    'job_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employmentStatusMeta = const VerificationMeta(
    'employmentStatus',
  );
  @override
  late final GeneratedColumn<String> employmentStatus = GeneratedColumn<String>(
    'employment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String>
  employmentStartDate = GeneratedColumn<String>(
    'employment_start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<LocalDate>($EmployeesTable.$converteremploymentStartDate);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  employmentEndDate = GeneratedColumn<String>(
    'employment_end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($EmployeesTable.$converteremploymentEndDaten);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    companyId,
    employeeNumber,
    firstName,
    middleName,
    lastName,
    displayName,
    phone,
    email,
    jobTitle,
    employmentStatus,
    employmentStartDate,
    employmentEndDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmployeeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('employee_number')) {
      context.handle(
        _employeeNumberMeta,
        employeeNumber.isAcceptableOrUnknown(
          data['employee_number']!,
          _employeeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_employeeNumberMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('middle_name')) {
      context.handle(
        _middleNameMeta,
        middleName.isAcceptableOrUnknown(data['middle_name']!, _middleNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('job_title')) {
      context.handle(
        _jobTitleMeta,
        jobTitle.isAcceptableOrUnknown(data['job_title']!, _jobTitleMeta),
      );
    }
    if (data.containsKey('employment_status')) {
      context.handle(
        _employmentStatusMeta,
        employmentStatus.isAcceptableOrUnknown(
          data['employment_status']!,
          _employmentStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_employmentStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {companyId, employeeNumber},
  ];
  @override
  EmployeeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncState: $EmployeesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      employeeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_number'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      middleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}middle_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      jobTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_title'],
      ),
      employmentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employment_status'],
      )!,
      employmentStartDate: $EmployeesTable.$converteremploymentStartDate
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}employment_start_date'],
            )!,
          ),
      employmentEndDate: $EmployeesTable.$converteremploymentEndDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}employment_end_date'],
        ),
      ),
    );
  }

  @override
  $EmployeesTable createAlias(String alias) {
    return $EmployeesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static TypeConverter<LocalDate, String> $converteremploymentStartDate =
      const LocalDateConverter();
  static TypeConverter<LocalDate, String> $converteremploymentEndDate =
      const LocalDateConverter();
  static TypeConverter<LocalDate?, String?> $converteremploymentEndDaten =
      NullAwareTypeConverter.wrap($converteremploymentEndDate);
}

class EmployeeRow extends DataClass implements Insertable<EmployeeRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final SyncState syncState;
  final DateTime? deletedAt;
  final String companyId;
  final String employeeNumber;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? displayName;
  final String? phone;
  final String? email;
  final String? jobTitle;
  final String employmentStatus;
  final LocalDate employmentStartDate;
  final LocalDate? employmentEndDate;
  const EmployeeRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncState,
    this.deletedAt,
    required this.companyId,
    required this.employeeNumber,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.displayName,
    this.phone,
    this.email,
    this.jobTitle,
    required this.employmentStatus,
    required this.employmentStartDate,
    this.employmentEndDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    {
      map['sync_state'] = Variable<String>(
        $EmployeesTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['company_id'] = Variable<String>(companyId);
    map['employee_number'] = Variable<String>(employeeNumber);
    map['first_name'] = Variable<String>(firstName);
    if (!nullToAbsent || middleName != null) {
      map['middle_name'] = Variable<String>(middleName);
    }
    map['last_name'] = Variable<String>(lastName);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || jobTitle != null) {
      map['job_title'] = Variable<String>(jobTitle);
    }
    map['employment_status'] = Variable<String>(employmentStatus);
    {
      map['employment_start_date'] = Variable<String>(
        $EmployeesTable.$converteremploymentStartDate.toSql(
          employmentStartDate,
        ),
      );
    }
    if (!nullToAbsent || employmentEndDate != null) {
      map['employment_end_date'] = Variable<String>(
        $EmployeesTable.$converteremploymentEndDaten.toSql(employmentEndDate),
      );
    }
    return map;
  }

  EmployeesCompanion toCompanion(bool nullToAbsent) {
    return EmployeesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      syncState: Value(syncState),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      companyId: Value(companyId),
      employeeNumber: Value(employeeNumber),
      firstName: Value(firstName),
      middleName: middleName == null && nullToAbsent
          ? const Value.absent()
          : Value(middleName),
      lastName: Value(lastName),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      jobTitle: jobTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(jobTitle),
      employmentStatus: Value(employmentStatus),
      employmentStartDate: Value(employmentStartDate),
      employmentEndDate: employmentEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(employmentEndDate),
    );
  }

  factory EmployeeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      syncState: $EmployeesTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      companyId: serializer.fromJson<String>(json['companyId']),
      employeeNumber: serializer.fromJson<String>(json['employeeNumber']),
      firstName: serializer.fromJson<String>(json['firstName']),
      middleName: serializer.fromJson<String?>(json['middleName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      jobTitle: serializer.fromJson<String?>(json['jobTitle']),
      employmentStatus: serializer.fromJson<String>(json['employmentStatus']),
      employmentStartDate: serializer.fromJson<LocalDate>(
        json['employmentStartDate'],
      ),
      employmentEndDate: serializer.fromJson<LocalDate?>(
        json['employmentEndDate'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'syncState': serializer.toJson<String>(
        $EmployeesTable.$convertersyncState.toJson(syncState),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'companyId': serializer.toJson<String>(companyId),
      'employeeNumber': serializer.toJson<String>(employeeNumber),
      'firstName': serializer.toJson<String>(firstName),
      'middleName': serializer.toJson<String?>(middleName),
      'lastName': serializer.toJson<String>(lastName),
      'displayName': serializer.toJson<String?>(displayName),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'jobTitle': serializer.toJson<String?>(jobTitle),
      'employmentStatus': serializer.toJson<String>(employmentStatus),
      'employmentStartDate': serializer.toJson<LocalDate>(employmentStartDate),
      'employmentEndDate': serializer.toJson<LocalDate?>(employmentEndDate),
    };
  }

  EmployeeRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    SyncState? syncState,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? companyId,
    String? employeeNumber,
    String? firstName,
    Value<String?> middleName = const Value.absent(),
    String? lastName,
    Value<String?> displayName = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> jobTitle = const Value.absent(),
    String? employmentStatus,
    LocalDate? employmentStartDate,
    Value<LocalDate?> employmentEndDate = const Value.absent(),
  }) => EmployeeRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    syncState: syncState ?? this.syncState,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    companyId: companyId ?? this.companyId,
    employeeNumber: employeeNumber ?? this.employeeNumber,
    firstName: firstName ?? this.firstName,
    middleName: middleName.present ? middleName.value : this.middleName,
    lastName: lastName ?? this.lastName,
    displayName: displayName.present ? displayName.value : this.displayName,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    jobTitle: jobTitle.present ? jobTitle.value : this.jobTitle,
    employmentStatus: employmentStatus ?? this.employmentStatus,
    employmentStartDate: employmentStartDate ?? this.employmentStartDate,
    employmentEndDate: employmentEndDate.present
        ? employmentEndDate.value
        : this.employmentEndDate,
  );
  EmployeeRow copyWithCompanion(EmployeesCompanion data) {
    return EmployeeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      employeeNumber: data.employeeNumber.present
          ? data.employeeNumber.value
          : this.employeeNumber,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      middleName: data.middleName.present
          ? data.middleName.value
          : this.middleName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      jobTitle: data.jobTitle.present ? data.jobTitle.value : this.jobTitle,
      employmentStatus: data.employmentStatus.present
          ? data.employmentStatus.value
          : this.employmentStatus,
      employmentStartDate: data.employmentStartDate.present
          ? data.employmentStartDate.value
          : this.employmentStartDate,
      employmentEndDate: data.employmentEndDate.present
          ? data.employmentEndDate.value
          : this.employmentEndDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('companyId: $companyId, ')
          ..write('employeeNumber: $employeeNumber, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('lastName: $lastName, ')
          ..write('displayName: $displayName, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('employmentStatus: $employmentStatus, ')
          ..write('employmentStartDate: $employmentStartDate, ')
          ..write('employmentEndDate: $employmentEndDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    companyId,
    employeeNumber,
    firstName,
    middleName,
    lastName,
    displayName,
    phone,
    email,
    jobTitle,
    employmentStatus,
    employmentStartDate,
    employmentEndDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.syncState == this.syncState &&
          other.deletedAt == this.deletedAt &&
          other.companyId == this.companyId &&
          other.employeeNumber == this.employeeNumber &&
          other.firstName == this.firstName &&
          other.middleName == this.middleName &&
          other.lastName == this.lastName &&
          other.displayName == this.displayName &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.jobTitle == this.jobTitle &&
          other.employmentStatus == this.employmentStatus &&
          other.employmentStartDate == this.employmentStartDate &&
          other.employmentEndDate == this.employmentEndDate);
}

class EmployeesCompanion extends UpdateCompanion<EmployeeRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<SyncState> syncState;
  final Value<DateTime?> deletedAt;
  final Value<String> companyId;
  final Value<String> employeeNumber;
  final Value<String> firstName;
  final Value<String?> middleName;
  final Value<String> lastName;
  final Value<String?> displayName;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> jobTitle;
  final Value<String> employmentStatus;
  final Value<LocalDate> employmentStartDate;
  final Value<LocalDate?> employmentEndDate;
  final Value<int> rowid;
  const EmployeesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.companyId = const Value.absent(),
    this.employeeNumber = const Value.absent(),
    this.firstName = const Value.absent(),
    this.middleName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.employmentStatus = const Value.absent(),
    this.employmentStartDate = const Value.absent(),
    this.employmentEndDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String companyId,
    required String employeeNumber,
    required String firstName,
    this.middleName = const Value.absent(),
    required String lastName,
    this.displayName = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.jobTitle = const Value.absent(),
    required String employmentStatus,
    required LocalDate employmentStartDate,
    this.employmentEndDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       companyId = Value(companyId),
       employeeNumber = Value(employeeNumber),
       firstName = Value(firstName),
       lastName = Value(lastName),
       employmentStatus = Value(employmentStatus),
       employmentStartDate = Value(employmentStartDate);
  static Insertable<EmployeeRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<String>? syncState,
    Expression<DateTime>? deletedAt,
    Expression<String>? companyId,
    Expression<String>? employeeNumber,
    Expression<String>? firstName,
    Expression<String>? middleName,
    Expression<String>? lastName,
    Expression<String>? displayName,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? jobTitle,
    Expression<String>? employmentStatus,
    Expression<String>? employmentStartDate,
    Expression<String>? employmentEndDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (syncState != null) 'sync_state': syncState,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (companyId != null) 'company_id': companyId,
      if (employeeNumber != null) 'employee_number': employeeNumber,
      if (firstName != null) 'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      if (lastName != null) 'last_name': lastName,
      if (displayName != null) 'display_name': displayName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (jobTitle != null) 'job_title': jobTitle,
      if (employmentStatus != null) 'employment_status': employmentStatus,
      if (employmentStartDate != null)
        'employment_start_date': employmentStartDate,
      if (employmentEndDate != null) 'employment_end_date': employmentEndDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<SyncState>? syncState,
    Value<DateTime?>? deletedAt,
    Value<String>? companyId,
    Value<String>? employeeNumber,
    Value<String>? firstName,
    Value<String?>? middleName,
    Value<String>? lastName,
    Value<String?>? displayName,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? jobTitle,
    Value<String>? employmentStatus,
    Value<LocalDate>? employmentStartDate,
    Value<LocalDate?>? employmentEndDate,
    Value<int>? rowid,
  }) {
    return EmployeesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      deletedAt: deletedAt ?? this.deletedAt,
      companyId: companyId ?? this.companyId,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      jobTitle: jobTitle ?? this.jobTitle,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      employmentEndDate: employmentEndDate ?? this.employmentEndDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $EmployeesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (employeeNumber.present) {
      map['employee_number'] = Variable<String>(employeeNumber.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (middleName.present) {
      map['middle_name'] = Variable<String>(middleName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (jobTitle.present) {
      map['job_title'] = Variable<String>(jobTitle.value);
    }
    if (employmentStatus.present) {
      map['employment_status'] = Variable<String>(employmentStatus.value);
    }
    if (employmentStartDate.present) {
      map['employment_start_date'] = Variable<String>(
        $EmployeesTable.$converteremploymentStartDate.toSql(
          employmentStartDate.value,
        ),
      );
    }
    if (employmentEndDate.present) {
      map['employment_end_date'] = Variable<String>(
        $EmployeesTable.$converteremploymentEndDaten.toSql(
          employmentEndDate.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('companyId: $companyId, ')
          ..write('employeeNumber: $employeeNumber, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('lastName: $lastName, ')
          ..write('displayName: $displayName, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('employmentStatus: $employmentStatus, ')
          ..write('employmentStartDate: $employmentStartDate, ')
          ..write('employmentEndDate: $employmentEndDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmployeeRatesTable extends EmployeeRates
    with TableInfo<$EmployeeRatesTable, EmployeeRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeeRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($EmployeeRatesTable.$convertersyncState);
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES employees (id)',
    ),
  );
  static const VerificationMeta _rateTypeMeta = const VerificationMeta(
    'rateType',
  );
  @override
  late final GeneratedColumn<String> rateType = GeneratedColumn<String>(
    'rate_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> effectiveFrom =
      GeneratedColumn<String>(
        'effective_from',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($EmployeeRatesTable.$convertereffectiveFrom);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> effectiveTo =
      GeneratedColumn<String>(
        'effective_to',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>($EmployeeRatesTable.$convertereffectiveTon);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    employeeId,
    rateType,
    amountMinor,
    currencyCode,
    effectiveFrom,
    effectiveTo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employee_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmployeeRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('rate_type')) {
      context.handle(
        _rateTypeMeta,
        rateType.isAcceptableOrUnknown(data['rate_type']!, _rateTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_rateTypeMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {employeeId, effectiveFrom},
  ];
  @override
  EmployeeRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeeRateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncState: $EmployeeRatesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      rateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate_type'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      effectiveFrom: $EmployeeRatesTable.$convertereffectiveFrom.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}effective_from'],
        )!,
      ),
      effectiveTo: $EmployeeRatesTable.$convertereffectiveTon.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}effective_to'],
        ),
      ),
    );
  }

  @override
  $EmployeeRatesTable createAlias(String alias) {
    return $EmployeeRatesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static TypeConverter<LocalDate, String> $convertereffectiveFrom =
      const LocalDateConverter();
  static TypeConverter<LocalDate, String> $convertereffectiveTo =
      const LocalDateConverter();
  static TypeConverter<LocalDate?, String?> $convertereffectiveTon =
      NullAwareTypeConverter.wrap($convertereffectiveTo);
}

class EmployeeRateRow extends DataClass implements Insertable<EmployeeRateRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final SyncState syncState;
  final DateTime? deletedAt;
  final String employeeId;
  final String rateType;

  /// Amount in the currency's minor unit (for example cents). Never a double.
  final int amountMinor;
  final String currencyCode;
  final LocalDate effectiveFrom;

  /// Inclusive last day; `null` while the rate is current.
  final LocalDate? effectiveTo;
  const EmployeeRateRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncState,
    this.deletedAt,
    required this.employeeId,
    required this.rateType,
    required this.amountMinor,
    required this.currencyCode,
    required this.effectiveFrom,
    this.effectiveTo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    {
      map['sync_state'] = Variable<String>(
        $EmployeeRatesTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['employee_id'] = Variable<String>(employeeId);
    map['rate_type'] = Variable<String>(rateType);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    {
      map['effective_from'] = Variable<String>(
        $EmployeeRatesTable.$convertereffectiveFrom.toSql(effectiveFrom),
      );
    }
    if (!nullToAbsent || effectiveTo != null) {
      map['effective_to'] = Variable<String>(
        $EmployeeRatesTable.$convertereffectiveTon.toSql(effectiveTo),
      );
    }
    return map;
  }

  EmployeeRatesCompanion toCompanion(bool nullToAbsent) {
    return EmployeeRatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      syncState: Value(syncState),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      employeeId: Value(employeeId),
      rateType: Value(rateType),
      amountMinor: Value(amountMinor),
      currencyCode: Value(currencyCode),
      effectiveFrom: Value(effectiveFrom),
      effectiveTo: effectiveTo == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveTo),
    );
  }

  factory EmployeeRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeeRateRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      syncState: $EmployeeRatesTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      rateType: serializer.fromJson<String>(json['rateType']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      effectiveFrom: serializer.fromJson<LocalDate>(json['effectiveFrom']),
      effectiveTo: serializer.fromJson<LocalDate?>(json['effectiveTo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'syncState': serializer.toJson<String>(
        $EmployeeRatesTable.$convertersyncState.toJson(syncState),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'employeeId': serializer.toJson<String>(employeeId),
      'rateType': serializer.toJson<String>(rateType),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'effectiveFrom': serializer.toJson<LocalDate>(effectiveFrom),
      'effectiveTo': serializer.toJson<LocalDate?>(effectiveTo),
    };
  }

  EmployeeRateRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    SyncState? syncState,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? employeeId,
    String? rateType,
    int? amountMinor,
    String? currencyCode,
    LocalDate? effectiveFrom,
    Value<LocalDate?> effectiveTo = const Value.absent(),
  }) => EmployeeRateRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    syncState: syncState ?? this.syncState,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    employeeId: employeeId ?? this.employeeId,
    rateType: rateType ?? this.rateType,
    amountMinor: amountMinor ?? this.amountMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    effectiveTo: effectiveTo.present ? effectiveTo.value : this.effectiveTo,
  );
  EmployeeRateRow copyWithCompanion(EmployeeRatesCompanion data) {
    return EmployeeRateRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      rateType: data.rateType.present ? data.rateType.value : this.rateType,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      effectiveTo: data.effectiveTo.present
          ? data.effectiveTo.value
          : this.effectiveTo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeRateRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('employeeId: $employeeId, ')
          ..write('rateType: $rateType, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveTo: $effectiveTo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    employeeId,
    rateType,
    amountMinor,
    currencyCode,
    effectiveFrom,
    effectiveTo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeeRateRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.syncState == this.syncState &&
          other.deletedAt == this.deletedAt &&
          other.employeeId == this.employeeId &&
          other.rateType == this.rateType &&
          other.amountMinor == this.amountMinor &&
          other.currencyCode == this.currencyCode &&
          other.effectiveFrom == this.effectiveFrom &&
          other.effectiveTo == this.effectiveTo);
}

class EmployeeRatesCompanion extends UpdateCompanion<EmployeeRateRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<SyncState> syncState;
  final Value<DateTime?> deletedAt;
  final Value<String> employeeId;
  final Value<String> rateType;
  final Value<int> amountMinor;
  final Value<String> currencyCode;
  final Value<LocalDate> effectiveFrom;
  final Value<LocalDate?> effectiveTo;
  final Value<int> rowid;
  const EmployeeRatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.rateType = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.effectiveTo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeeRatesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String employeeId,
    required String rateType,
    required int amountMinor,
    required String currencyCode,
    required LocalDate effectiveFrom,
    this.effectiveTo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       employeeId = Value(employeeId),
       rateType = Value(rateType),
       amountMinor = Value(amountMinor),
       currencyCode = Value(currencyCode),
       effectiveFrom = Value(effectiveFrom);
  static Insertable<EmployeeRateRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<String>? syncState,
    Expression<DateTime>? deletedAt,
    Expression<String>? employeeId,
    Expression<String>? rateType,
    Expression<int>? amountMinor,
    Expression<String>? currencyCode,
    Expression<String>? effectiveFrom,
    Expression<String>? effectiveTo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (syncState != null) 'sync_state': syncState,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (employeeId != null) 'employee_id': employeeId,
      if (rateType != null) 'rate_type': rateType,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (effectiveTo != null) 'effective_to': effectiveTo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeeRatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<SyncState>? syncState,
    Value<DateTime?>? deletedAt,
    Value<String>? employeeId,
    Value<String>? rateType,
    Value<int>? amountMinor,
    Value<String>? currencyCode,
    Value<LocalDate>? effectiveFrom,
    Value<LocalDate?>? effectiveTo,
    Value<int>? rowid,
  }) {
    return EmployeeRatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      deletedAt: deletedAt ?? this.deletedAt,
      employeeId: employeeId ?? this.employeeId,
      rateType: rateType ?? this.rateType,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $EmployeeRatesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (rateType.present) {
      map['rate_type'] = Variable<String>(rateType.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<String>(
        $EmployeeRatesTable.$convertereffectiveFrom.toSql(effectiveFrom.value),
      );
    }
    if (effectiveTo.present) {
      map['effective_to'] = Variable<String>(
        $EmployeeRatesTable.$convertereffectiveTon.toSql(effectiveTo.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeRatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('employeeId: $employeeId, ')
          ..write('rateType: $rateType, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveTo: $effectiveTo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CredentialsTable extends Credentials
    with TableInfo<$CredentialsTable, CredentialRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CredentialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adminUserIdMeta = const VerificationMeta(
    'adminUserId',
  );
  @override
  late final GeneratedColumn<String> adminUserId = GeneratedColumn<String>(
    'admin_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES admin_users (id)',
    ),
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES employees (id)',
    ),
  );
  static const VerificationMeta _secretHashMeta = const VerificationMeta(
    'secretHash',
  );
  @override
  late final GeneratedColumn<String> secretHash = GeneratedColumn<String>(
    'secret_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTemporaryMeta = const VerificationMeta(
    'isTemporary',
  );
  @override
  late final GeneratedColumn<bool> isTemporary = GeneratedColumn<bool>(
    'is_temporary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_temporary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _failedAttemptsMeta = const VerificationMeta(
    'failedAttempts',
  );
  @override
  late final GeneratedColumn<int> failedAttempts = GeneratedColumn<int>(
    'failed_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockedUntilMeta = const VerificationMeta(
    'lockedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> lockedUntil = GeneratedColumn<DateTime>(
    'locked_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    adminUserId,
    employeeId,
    secretHash,
    isTemporary,
    failedAttempts,
    lockedUntil,
    changedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credentials';
  @override
  VerificationContext validateIntegrity(
    Insertable<CredentialRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('admin_user_id')) {
      context.handle(
        _adminUserIdMeta,
        adminUserId.isAcceptableOrUnknown(
          data['admin_user_id']!,
          _adminUserIdMeta,
        ),
      );
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    }
    if (data.containsKey('secret_hash')) {
      context.handle(
        _secretHashMeta,
        secretHash.isAcceptableOrUnknown(data['secret_hash']!, _secretHashMeta),
      );
    } else if (isInserting) {
      context.missing(_secretHashMeta);
    }
    if (data.containsKey('is_temporary')) {
      context.handle(
        _isTemporaryMeta,
        isTemporary.isAcceptableOrUnknown(
          data['is_temporary']!,
          _isTemporaryMeta,
        ),
      );
    }
    if (data.containsKey('failed_attempts')) {
      context.handle(
        _failedAttemptsMeta,
        failedAttempts.isAcceptableOrUnknown(
          data['failed_attempts']!,
          _failedAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('locked_until')) {
      context.handle(
        _lockedUntilMeta,
        lockedUntil.isAcceptableOrUnknown(
          data['locked_until']!,
          _lockedUntilMeta,
        ),
      );
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CredentialRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CredentialRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      adminUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}admin_user_id'],
      ),
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      ),
      secretHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_hash'],
      )!,
      isTemporary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_temporary'],
      )!,
      failedAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_attempts'],
      )!,
      lockedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_until'],
      ),
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CredentialsTable createAlias(String alias) {
    return $CredentialsTable(attachedDatabase, alias);
  }
}

class CredentialRow extends DataClass implements Insertable<CredentialRow> {
  final String id;

  /// `adminPassword` or `employeePin`.
  final String kind;
  final String? adminUserId;
  final String? employeeId;

  /// Self-describing hash; see `SecretHasher`.
  final String secretHash;

  /// Issued by an administrator; the owner must replace it on first use.
  final bool isTemporary;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final DateTime changedAt;
  final DateTime updatedAt;
  const CredentialRow({
    required this.id,
    required this.kind,
    this.adminUserId,
    this.employeeId,
    required this.secretHash,
    required this.isTemporary,
    required this.failedAttempts,
    this.lockedUntil,
    required this.changedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || adminUserId != null) {
      map['admin_user_id'] = Variable<String>(adminUserId);
    }
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<String>(employeeId);
    }
    map['secret_hash'] = Variable<String>(secretHash);
    map['is_temporary'] = Variable<bool>(isTemporary);
    map['failed_attempts'] = Variable<int>(failedAttempts);
    if (!nullToAbsent || lockedUntil != null) {
      map['locked_until'] = Variable<DateTime>(lockedUntil);
    }
    map['changed_at'] = Variable<DateTime>(changedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CredentialsCompanion toCompanion(bool nullToAbsent) {
    return CredentialsCompanion(
      id: Value(id),
      kind: Value(kind),
      adminUserId: adminUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(adminUserId),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      secretHash: Value(secretHash),
      isTemporary: Value(isTemporary),
      failedAttempts: Value(failedAttempts),
      lockedUntil: lockedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedUntil),
      changedAt: Value(changedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CredentialRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CredentialRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      adminUserId: serializer.fromJson<String?>(json['adminUserId']),
      employeeId: serializer.fromJson<String?>(json['employeeId']),
      secretHash: serializer.fromJson<String>(json['secretHash']),
      isTemporary: serializer.fromJson<bool>(json['isTemporary']),
      failedAttempts: serializer.fromJson<int>(json['failedAttempts']),
      lockedUntil: serializer.fromJson<DateTime?>(json['lockedUntil']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'adminUserId': serializer.toJson<String?>(adminUserId),
      'employeeId': serializer.toJson<String?>(employeeId),
      'secretHash': serializer.toJson<String>(secretHash),
      'isTemporary': serializer.toJson<bool>(isTemporary),
      'failedAttempts': serializer.toJson<int>(failedAttempts),
      'lockedUntil': serializer.toJson<DateTime?>(lockedUntil),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CredentialRow copyWith({
    String? id,
    String? kind,
    Value<String?> adminUserId = const Value.absent(),
    Value<String?> employeeId = const Value.absent(),
    String? secretHash,
    bool? isTemporary,
    int? failedAttempts,
    Value<DateTime?> lockedUntil = const Value.absent(),
    DateTime? changedAt,
    DateTime? updatedAt,
  }) => CredentialRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    adminUserId: adminUserId.present ? adminUserId.value : this.adminUserId,
    employeeId: employeeId.present ? employeeId.value : this.employeeId,
    secretHash: secretHash ?? this.secretHash,
    isTemporary: isTemporary ?? this.isTemporary,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: lockedUntil.present ? lockedUntil.value : this.lockedUntil,
    changedAt: changedAt ?? this.changedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CredentialRow copyWithCompanion(CredentialsCompanion data) {
    return CredentialRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      adminUserId: data.adminUserId.present
          ? data.adminUserId.value
          : this.adminUserId,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      secretHash: data.secretHash.present
          ? data.secretHash.value
          : this.secretHash,
      isTemporary: data.isTemporary.present
          ? data.isTemporary.value
          : this.isTemporary,
      failedAttempts: data.failedAttempts.present
          ? data.failedAttempts.value
          : this.failedAttempts,
      lockedUntil: data.lockedUntil.present
          ? data.lockedUntil.value
          : this.lockedUntil,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CredentialRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('adminUserId: $adminUserId, ')
          ..write('employeeId: $employeeId, ')
          ..write('secretHash: $secretHash, ')
          ..write('isTemporary: $isTemporary, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('changedAt: $changedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    adminUserId,
    employeeId,
    secretHash,
    isTemporary,
    failedAttempts,
    lockedUntil,
    changedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CredentialRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.adminUserId == this.adminUserId &&
          other.employeeId == this.employeeId &&
          other.secretHash == this.secretHash &&
          other.isTemporary == this.isTemporary &&
          other.failedAttempts == this.failedAttempts &&
          other.lockedUntil == this.lockedUntil &&
          other.changedAt == this.changedAt &&
          other.updatedAt == this.updatedAt);
}

class CredentialsCompanion extends UpdateCompanion<CredentialRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> adminUserId;
  final Value<String?> employeeId;
  final Value<String> secretHash;
  final Value<bool> isTemporary;
  final Value<int> failedAttempts;
  final Value<DateTime?> lockedUntil;
  final Value<DateTime> changedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CredentialsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.adminUserId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.secretHash = const Value.absent(),
    this.isTemporary = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CredentialsCompanion.insert({
    required String id,
    required String kind,
    this.adminUserId = const Value.absent(),
    this.employeeId = const Value.absent(),
    required String secretHash,
    this.isTemporary = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    required DateTime changedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       secretHash = Value(secretHash),
       changedAt = Value(changedAt),
       updatedAt = Value(updatedAt);
  static Insertable<CredentialRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? adminUserId,
    Expression<String>? employeeId,
    Expression<String>? secretHash,
    Expression<bool>? isTemporary,
    Expression<int>? failedAttempts,
    Expression<DateTime>? lockedUntil,
    Expression<DateTime>? changedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (adminUserId != null) 'admin_user_id': adminUserId,
      if (employeeId != null) 'employee_id': employeeId,
      if (secretHash != null) 'secret_hash': secretHash,
      if (isTemporary != null) 'is_temporary': isTemporary,
      if (failedAttempts != null) 'failed_attempts': failedAttempts,
      if (lockedUntil != null) 'locked_until': lockedUntil,
      if (changedAt != null) 'changed_at': changedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CredentialsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String?>? adminUserId,
    Value<String?>? employeeId,
    Value<String>? secretHash,
    Value<bool>? isTemporary,
    Value<int>? failedAttempts,
    Value<DateTime?>? lockedUntil,
    Value<DateTime>? changedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CredentialsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      adminUserId: adminUserId ?? this.adminUserId,
      employeeId: employeeId ?? this.employeeId,
      secretHash: secretHash ?? this.secretHash,
      isTemporary: isTemporary ?? this.isTemporary,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      changedAt: changedAt ?? this.changedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (adminUserId.present) {
      map['admin_user_id'] = Variable<String>(adminUserId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (secretHash.present) {
      map['secret_hash'] = Variable<String>(secretHash.value);
    }
    if (isTemporary.present) {
      map['is_temporary'] = Variable<bool>(isTemporary.value);
    }
    if (failedAttempts.present) {
      map['failed_attempts'] = Variable<int>(failedAttempts.value);
    }
    if (lockedUntil.present) {
      map['locked_until'] = Variable<DateTime>(lockedUntil.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CredentialsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('adminUserId: $adminUserId, ')
          ..write('employeeId: $employeeId, ')
          ..write('secretHash: $secretHash, ')
          ..write('isTemporary: $isTemporary, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('changedAt: $changedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES companies (id)',
    ),
  );
  static const VerificationMeta _actorTypeMeta = const VerificationMeta(
    'actorType',
  );
  @override
  late final GeneratedColumn<String> actorType = GeneratedColumn<String>(
    'actor_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($AuditLogTable.$convertersyncState);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    actorType,
    actorId,
    action,
    entityType,
    entityId,
    occurredAt,
    deviceId,
    metadata,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('actor_type')) {
      context.handle(
        _actorTypeMeta,
        actorType.isAcceptableOrUnknown(data['actor_type']!, _actorTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actorTypeMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      actorType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_type'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      ),
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      syncState: $AuditLogTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class AuditLogRow extends DataClass implements Insertable<AuditLogRow> {
  final String id;
  final String companyId;

  /// `admin`, `employee` or `system`.
  final String actorType;
  final String? actorId;

  /// Stable dotted code, for example `employee.pin_reset`.
  final String action;
  final String entityType;
  final String? entityId;
  final DateTime occurredAt;
  final String deviceId;

  /// JSON object with non-sensitive details, or null.
  final String? metadata;
  final SyncState syncState;
  const AuditLogRow({
    required this.id,
    required this.companyId,
    required this.actorType,
    this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    required this.occurredAt,
    required this.deviceId,
    this.metadata,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['actor_type'] = Variable<String>(actorType);
    if (!nullToAbsent || actorId != null) {
      map['actor_id'] = Variable<String>(actorId);
    }
    map['action'] = Variable<String>(action);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    {
      map['sync_state'] = Variable<String>(
        $AuditLogTable.$convertersyncState.toSql(syncState),
      );
    }
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      companyId: Value(companyId),
      actorType: Value(actorType),
      actorId: actorId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorId),
      action: Value(action),
      entityType: Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      occurredAt: Value(occurredAt),
      deviceId: Value(deviceId),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      syncState: Value(syncState),
    );
  }

  factory AuditLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRow(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      actorType: serializer.fromJson<String>(json['actorType']),
      actorId: serializer.fromJson<String?>(json['actorId']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      syncState: $AuditLogTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'actorType': serializer.toJson<String>(actorType),
      'actorId': serializer.toJson<String?>(actorId),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'metadata': serializer.toJson<String?>(metadata),
      'syncState': serializer.toJson<String>(
        $AuditLogTable.$convertersyncState.toJson(syncState),
      ),
    };
  }

  AuditLogRow copyWith({
    String? id,
    String? companyId,
    String? actorType,
    Value<String?> actorId = const Value.absent(),
    String? action,
    String? entityType,
    Value<String?> entityId = const Value.absent(),
    DateTime? occurredAt,
    String? deviceId,
    Value<String?> metadata = const Value.absent(),
    SyncState? syncState,
  }) => AuditLogRow(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    actorType: actorType ?? this.actorType,
    actorId: actorId.present ? actorId.value : this.actorId,
    action: action ?? this.action,
    entityType: entityType ?? this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    occurredAt: occurredAt ?? this.occurredAt,
    deviceId: deviceId ?? this.deviceId,
    metadata: metadata.present ? metadata.value : this.metadata,
    syncState: syncState ?? this.syncState,
  );
  AuditLogRow copyWithCompanion(AuditLogCompanion data) {
    return AuditLogRow(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      actorType: data.actorType.present ? data.actorType.value : this.actorType,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      action: data.action.present ? data.action.value : this.action,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRow(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('actorType: $actorType, ')
          ..write('actorId: $actorId, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('metadata: $metadata, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    actorType,
    actorId,
    action,
    entityType,
    entityId,
    occurredAt,
    deviceId,
    metadata,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRow &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.actorType == this.actorType &&
          other.actorId == this.actorId &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.occurredAt == this.occurredAt &&
          other.deviceId == this.deviceId &&
          other.metadata == this.metadata &&
          other.syncState == this.syncState);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> actorType;
  final Value<String?> actorId;
  final Value<String> action;
  final Value<String> entityType;
  final Value<String?> entityId;
  final Value<DateTime> occurredAt;
  final Value<String> deviceId;
  final Value<String?> metadata;
  final Value<SyncState> syncState;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.actorType = const Value.absent(),
    this.actorId = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogCompanion.insert({
    required String id,
    required String companyId,
    required String actorType,
    this.actorId = const Value.absent(),
    required String action,
    required String entityType,
    this.entityId = const Value.absent(),
    required DateTime occurredAt,
    required String deviceId,
    this.metadata = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       actorType = Value(actorType),
       action = Value(action),
       entityType = Value(entityType),
       occurredAt = Value(occurredAt),
       deviceId = Value(deviceId);
  static Insertable<AuditLogRow> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? actorType,
    Expression<String>? actorId,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<DateTime>? occurredAt,
    Expression<String>? deviceId,
    Expression<String>? metadata,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (actorType != null) 'actor_type': actorType,
      if (actorId != null) 'actor_id': actorId,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (deviceId != null) 'device_id': deviceId,
      if (metadata != null) 'metadata': metadata,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? actorType,
    Value<String?>? actorId,
    Value<String>? action,
    Value<String>? entityType,
    Value<String?>? entityId,
    Value<DateTime>? occurredAt,
    Value<String>? deviceId,
    Value<String?>? metadata,
    Value<SyncState>? syncState,
    Value<int>? rowid,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      actorType: actorType ?? this.actorType,
      actorId: actorId ?? this.actorId,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      occurredAt: occurredAt ?? this.occurredAt,
      deviceId: deviceId ?? this.deviceId,
      metadata: metadata ?? this.metadata,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (actorType.present) {
      map['actor_type'] = Variable<String>(actorType.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $AuditLogTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('actorType: $actorType, ')
          ..write('actorId: $actorId, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('metadata: $metadata, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceIdentityTable extends DeviceIdentity
    with TableInfo<$DeviceIdentityTable, DeviceIdentityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceIdentityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_identity';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceIdentityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceIdentityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceIdentityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DeviceIdentityTable createAlias(String alias) {
    return $DeviceIdentityTable(attachedDatabase, alias);
  }
}

class DeviceIdentityRow extends DataClass
    implements Insertable<DeviceIdentityRow> {
  final String id;
  final DateTime createdAt;
  const DeviceIdentityRow({required this.id, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DeviceIdentityCompanion toCompanion(bool nullToAbsent) {
    return DeviceIdentityCompanion(id: Value(id), createdAt: Value(createdAt));
  }

  factory DeviceIdentityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceIdentityRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DeviceIdentityRow copyWith({String? id, DateTime? createdAt}) =>
      DeviceIdentityRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
      );
  DeviceIdentityRow copyWithCompanion(DeviceIdentityCompanion data) {
    return DeviceIdentityRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceIdentityRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceIdentityRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt);
}

class DeviceIdentityCompanion extends UpdateCompanion<DeviceIdentityRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DeviceIdentityCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceIdentityCompanion.insert({
    required String id,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt);
  static Insertable<DeviceIdentityRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceIdentityCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DeviceIdentityCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceIdentityCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceEventsTable extends AttendanceEvents
    with TableInfo<$AttendanceEventsTable, AttendanceEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($AttendanceEventsTable.$convertersyncState);
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES employees (id)',
    ),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    employeeId,
    eventType,
    occurredAt,
    recordedAt,
    source,
    deviceId,
    createdBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncState: $AttendanceEventsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
    );
  }

  @override
  $AttendanceEventsTable createAlias(String alias) {
    return $AttendanceEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class AttendanceEventRow extends DataClass
    implements Insertable<AttendanceEventRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final SyncState syncState;
  final DateTime? deletedAt;
  final String employeeId;

  /// `clockIn` or `clockOut`.
  final String eventType;

  /// When the action happened (UTC).
  final DateTime occurredAt;

  /// When this device stored it (UTC).
  final DateTime recordedAt;

  /// For example `kiosk`.
  final String source;
  final String deviceId;

  /// Who recorded it (employee or administrator id).
  final String createdBy;
  const AttendanceEventRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncState,
    this.deletedAt,
    required this.employeeId,
    required this.eventType,
    required this.occurredAt,
    required this.recordedAt,
    required this.source,
    required this.deviceId,
    required this.createdBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    {
      map['sync_state'] = Variable<String>(
        $AttendanceEventsTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['employee_id'] = Variable<String>(employeeId);
    map['event_type'] = Variable<String>(eventType);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['source'] = Variable<String>(source);
    map['device_id'] = Variable<String>(deviceId);
    map['created_by'] = Variable<String>(createdBy);
    return map;
  }

  AttendanceEventsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceEventsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      syncState: Value(syncState),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      employeeId: Value(employeeId),
      eventType: Value(eventType),
      occurredAt: Value(occurredAt),
      recordedAt: Value(recordedAt),
      source: Value(source),
      deviceId: Value(deviceId),
      createdBy: Value(createdBy),
    );
  }

  factory AttendanceEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceEventRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      syncState: $AttendanceEventsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      source: serializer.fromJson<String>(json['source']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'syncState': serializer.toJson<String>(
        $AttendanceEventsTable.$convertersyncState.toJson(syncState),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'employeeId': serializer.toJson<String>(employeeId),
      'eventType': serializer.toJson<String>(eventType),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'source': serializer.toJson<String>(source),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdBy': serializer.toJson<String>(createdBy),
    };
  }

  AttendanceEventRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    SyncState? syncState,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? employeeId,
    String? eventType,
    DateTime? occurredAt,
    DateTime? recordedAt,
    String? source,
    String? deviceId,
    String? createdBy,
  }) => AttendanceEventRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    syncState: syncState ?? this.syncState,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    employeeId: employeeId ?? this.employeeId,
    eventType: eventType ?? this.eventType,
    occurredAt: occurredAt ?? this.occurredAt,
    recordedAt: recordedAt ?? this.recordedAt,
    source: source ?? this.source,
    deviceId: deviceId ?? this.deviceId,
    createdBy: createdBy ?? this.createdBy,
  );
  AttendanceEventRow copyWithCompanion(AttendanceEventsCompanion data) {
    return AttendanceEventRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      source: data.source.present ? data.source.value : this.source,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceEventRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('employeeId: $employeeId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('source: $source, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdBy: $createdBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    employeeId,
    eventType,
    occurredAt,
    recordedAt,
    source,
    deviceId,
    createdBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceEventRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.syncState == this.syncState &&
          other.deletedAt == this.deletedAt &&
          other.employeeId == this.employeeId &&
          other.eventType == this.eventType &&
          other.occurredAt == this.occurredAt &&
          other.recordedAt == this.recordedAt &&
          other.source == this.source &&
          other.deviceId == this.deviceId &&
          other.createdBy == this.createdBy);
}

class AttendanceEventsCompanion extends UpdateCompanion<AttendanceEventRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<SyncState> syncState;
  final Value<DateTime?> deletedAt;
  final Value<String> employeeId;
  final Value<String> eventType;
  final Value<DateTime> occurredAt;
  final Value<DateTime> recordedAt;
  final Value<String> source;
  final Value<String> deviceId;
  final Value<String> createdBy;
  final Value<int> rowid;
  const AttendanceEventsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceEventsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String employeeId,
    required String eventType,
    required DateTime occurredAt,
    required DateTime recordedAt,
    required String source,
    required String deviceId,
    required String createdBy,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       employeeId = Value(employeeId),
       eventType = Value(eventType),
       occurredAt = Value(occurredAt),
       recordedAt = Value(recordedAt),
       source = Value(source),
       deviceId = Value(deviceId),
       createdBy = Value(createdBy);
  static Insertable<AttendanceEventRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<String>? syncState,
    Expression<DateTime>? deletedAt,
    Expression<String>? employeeId,
    Expression<String>? eventType,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? recordedAt,
    Expression<String>? source,
    Expression<String>? deviceId,
    Expression<String>? createdBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (syncState != null) 'sync_state': syncState,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (employeeId != null) 'employee_id': employeeId,
      if (eventType != null) 'event_type': eventType,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (source != null) 'source': source,
      if (deviceId != null) 'device_id': deviceId,
      if (createdBy != null) 'created_by': createdBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceEventsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<SyncState>? syncState,
    Value<DateTime?>? deletedAt,
    Value<String>? employeeId,
    Value<String>? eventType,
    Value<DateTime>? occurredAt,
    Value<DateTime>? recordedAt,
    Value<String>? source,
    Value<String>? deviceId,
    Value<String>? createdBy,
    Value<int>? rowid,
  }) {
    return AttendanceEventsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      deletedAt: deletedAt ?? this.deletedAt,
      employeeId: employeeId ?? this.employeeId,
      eventType: eventType ?? this.eventType,
      occurredAt: occurredAt ?? this.occurredAt,
      recordedAt: recordedAt ?? this.recordedAt,
      source: source ?? this.source,
      deviceId: deviceId ?? this.deviceId,
      createdBy: createdBy ?? this.createdBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $AttendanceEventsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceEventsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('employeeId: $employeeId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('source: $source, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdBy: $createdBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceSettingsTable extends AttendanceSettings
    with TableInfo<$AttendanceSettingsTable, AttendanceSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($AttendanceSettingsTable.$convertersyncState);
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES companies (id)',
    ),
  );
  static const VerificationMeta _duplicateWindowMinutesMeta =
      const VerificationMeta('duplicateWindowMinutes');
  @override
  late final GeneratedColumn<int> duplicateWindowMinutes = GeneratedColumn<int>(
    'duplicate_window_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staleOpenSessionMinutesMeta =
      const VerificationMeta('staleOpenSessionMinutes');
  @override
  late final GeneratedColumn<int> staleOpenSessionMinutes =
      GeneratedColumn<int>(
        'stale_open_session_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _excessiveDurationMinutesMeta =
      const VerificationMeta('excessiveDurationMinutes');
  @override
  late final GeneratedColumn<int> excessiveDurationMinutes =
      GeneratedColumn<int>(
        'excessive_duration_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _breakAfterMinutesMeta = const VerificationMeta(
    'breakAfterMinutes',
  );
  @override
  late final GeneratedColumn<int> breakAfterMinutes = GeneratedColumn<int>(
    'break_after_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _breakMinutesMeta = const VerificationMeta(
    'breakMinutes',
  );
  @override
  late final GeneratedColumn<int> breakMinutes = GeneratedColumn<int>(
    'break_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    companyId,
    duplicateWindowMinutes,
    staleOpenSessionMinutes,
    excessiveDurationMinutes,
    breakAfterMinutes,
    breakMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('duplicate_window_minutes')) {
      context.handle(
        _duplicateWindowMinutesMeta,
        duplicateWindowMinutes.isAcceptableOrUnknown(
          data['duplicate_window_minutes']!,
          _duplicateWindowMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_duplicateWindowMinutesMeta);
    }
    if (data.containsKey('stale_open_session_minutes')) {
      context.handle(
        _staleOpenSessionMinutesMeta,
        staleOpenSessionMinutes.isAcceptableOrUnknown(
          data['stale_open_session_minutes']!,
          _staleOpenSessionMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_staleOpenSessionMinutesMeta);
    }
    if (data.containsKey('excessive_duration_minutes')) {
      context.handle(
        _excessiveDurationMinutesMeta,
        excessiveDurationMinutes.isAcceptableOrUnknown(
          data['excessive_duration_minutes']!,
          _excessiveDurationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_excessiveDurationMinutesMeta);
    }
    if (data.containsKey('break_after_minutes')) {
      context.handle(
        _breakAfterMinutesMeta,
        breakAfterMinutes.isAcceptableOrUnknown(
          data['break_after_minutes']!,
          _breakAfterMinutesMeta,
        ),
      );
    }
    if (data.containsKey('break_minutes')) {
      context.handle(
        _breakMinutesMeta,
        breakMinutes.isAcceptableOrUnknown(
          data['break_minutes']!,
          _breakMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncState: $AttendanceSettingsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      duplicateWindowMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duplicate_window_minutes'],
      )!,
      staleOpenSessionMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stale_open_session_minutes'],
      )!,
      excessiveDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}excessive_duration_minutes'],
      )!,
      breakAfterMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}break_after_minutes'],
      ),
      breakMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}break_minutes'],
      ),
    );
  }

  @override
  $AttendanceSettingsTable createAlias(String alias) {
    return $AttendanceSettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class AttendanceSettingsRow extends DataClass
    implements Insertable<AttendanceSettingsRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final SyncState syncState;
  final DateTime? deletedAt;
  final String companyId;
  final int duplicateWindowMinutes;
  final int staleOpenSessionMinutes;
  final int excessiveDurationMinutes;

  /// Both set, or both null when there is no automatic break.
  final int? breakAfterMinutes;
  final int? breakMinutes;
  const AttendanceSettingsRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncState,
    this.deletedAt,
    required this.companyId,
    required this.duplicateWindowMinutes,
    required this.staleOpenSessionMinutes,
    required this.excessiveDurationMinutes,
    this.breakAfterMinutes,
    this.breakMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    {
      map['sync_state'] = Variable<String>(
        $AttendanceSettingsTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['company_id'] = Variable<String>(companyId);
    map['duplicate_window_minutes'] = Variable<int>(duplicateWindowMinutes);
    map['stale_open_session_minutes'] = Variable<int>(staleOpenSessionMinutes);
    map['excessive_duration_minutes'] = Variable<int>(excessiveDurationMinutes);
    if (!nullToAbsent || breakAfterMinutes != null) {
      map['break_after_minutes'] = Variable<int>(breakAfterMinutes);
    }
    if (!nullToAbsent || breakMinutes != null) {
      map['break_minutes'] = Variable<int>(breakMinutes);
    }
    return map;
  }

  AttendanceSettingsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceSettingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      syncState: Value(syncState),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      companyId: Value(companyId),
      duplicateWindowMinutes: Value(duplicateWindowMinutes),
      staleOpenSessionMinutes: Value(staleOpenSessionMinutes),
      excessiveDurationMinutes: Value(excessiveDurationMinutes),
      breakAfterMinutes: breakAfterMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(breakAfterMinutes),
      breakMinutes: breakMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(breakMinutes),
    );
  }

  factory AttendanceSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceSettingsRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      syncState: $AttendanceSettingsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      companyId: serializer.fromJson<String>(json['companyId']),
      duplicateWindowMinutes: serializer.fromJson<int>(
        json['duplicateWindowMinutes'],
      ),
      staleOpenSessionMinutes: serializer.fromJson<int>(
        json['staleOpenSessionMinutes'],
      ),
      excessiveDurationMinutes: serializer.fromJson<int>(
        json['excessiveDurationMinutes'],
      ),
      breakAfterMinutes: serializer.fromJson<int?>(json['breakAfterMinutes']),
      breakMinutes: serializer.fromJson<int?>(json['breakMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'syncState': serializer.toJson<String>(
        $AttendanceSettingsTable.$convertersyncState.toJson(syncState),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'companyId': serializer.toJson<String>(companyId),
      'duplicateWindowMinutes': serializer.toJson<int>(duplicateWindowMinutes),
      'staleOpenSessionMinutes': serializer.toJson<int>(
        staleOpenSessionMinutes,
      ),
      'excessiveDurationMinutes': serializer.toJson<int>(
        excessiveDurationMinutes,
      ),
      'breakAfterMinutes': serializer.toJson<int?>(breakAfterMinutes),
      'breakMinutes': serializer.toJson<int?>(breakMinutes),
    };
  }

  AttendanceSettingsRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    SyncState? syncState,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? companyId,
    int? duplicateWindowMinutes,
    int? staleOpenSessionMinutes,
    int? excessiveDurationMinutes,
    Value<int?> breakAfterMinutes = const Value.absent(),
    Value<int?> breakMinutes = const Value.absent(),
  }) => AttendanceSettingsRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    syncState: syncState ?? this.syncState,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    companyId: companyId ?? this.companyId,
    duplicateWindowMinutes:
        duplicateWindowMinutes ?? this.duplicateWindowMinutes,
    staleOpenSessionMinutes:
        staleOpenSessionMinutes ?? this.staleOpenSessionMinutes,
    excessiveDurationMinutes:
        excessiveDurationMinutes ?? this.excessiveDurationMinutes,
    breakAfterMinutes: breakAfterMinutes.present
        ? breakAfterMinutes.value
        : this.breakAfterMinutes,
    breakMinutes: breakMinutes.present ? breakMinutes.value : this.breakMinutes,
  );
  AttendanceSettingsRow copyWithCompanion(AttendanceSettingsCompanion data) {
    return AttendanceSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      duplicateWindowMinutes: data.duplicateWindowMinutes.present
          ? data.duplicateWindowMinutes.value
          : this.duplicateWindowMinutes,
      staleOpenSessionMinutes: data.staleOpenSessionMinutes.present
          ? data.staleOpenSessionMinutes.value
          : this.staleOpenSessionMinutes,
      excessiveDurationMinutes: data.excessiveDurationMinutes.present
          ? data.excessiveDurationMinutes.value
          : this.excessiveDurationMinutes,
      breakAfterMinutes: data.breakAfterMinutes.present
          ? data.breakAfterMinutes.value
          : this.breakAfterMinutes,
      breakMinutes: data.breakMinutes.present
          ? data.breakMinutes.value
          : this.breakMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceSettingsRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('companyId: $companyId, ')
          ..write('duplicateWindowMinutes: $duplicateWindowMinutes, ')
          ..write('staleOpenSessionMinutes: $staleOpenSessionMinutes, ')
          ..write('excessiveDurationMinutes: $excessiveDurationMinutes, ')
          ..write('breakAfterMinutes: $breakAfterMinutes, ')
          ..write('breakMinutes: $breakMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    companyId,
    duplicateWindowMinutes,
    staleOpenSessionMinutes,
    excessiveDurationMinutes,
    breakAfterMinutes,
    breakMinutes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceSettingsRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.syncState == this.syncState &&
          other.deletedAt == this.deletedAt &&
          other.companyId == this.companyId &&
          other.duplicateWindowMinutes == this.duplicateWindowMinutes &&
          other.staleOpenSessionMinutes == this.staleOpenSessionMinutes &&
          other.excessiveDurationMinutes == this.excessiveDurationMinutes &&
          other.breakAfterMinutes == this.breakAfterMinutes &&
          other.breakMinutes == this.breakMinutes);
}

class AttendanceSettingsCompanion
    extends UpdateCompanion<AttendanceSettingsRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<SyncState> syncState;
  final Value<DateTime?> deletedAt;
  final Value<String> companyId;
  final Value<int> duplicateWindowMinutes;
  final Value<int> staleOpenSessionMinutes;
  final Value<int> excessiveDurationMinutes;
  final Value<int?> breakAfterMinutes;
  final Value<int?> breakMinutes;
  final Value<int> rowid;
  const AttendanceSettingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.companyId = const Value.absent(),
    this.duplicateWindowMinutes = const Value.absent(),
    this.staleOpenSessionMinutes = const Value.absent(),
    this.excessiveDurationMinutes = const Value.absent(),
    this.breakAfterMinutes = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceSettingsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String companyId,
    required int duplicateWindowMinutes,
    required int staleOpenSessionMinutes,
    required int excessiveDurationMinutes,
    this.breakAfterMinutes = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       companyId = Value(companyId),
       duplicateWindowMinutes = Value(duplicateWindowMinutes),
       staleOpenSessionMinutes = Value(staleOpenSessionMinutes),
       excessiveDurationMinutes = Value(excessiveDurationMinutes);
  static Insertable<AttendanceSettingsRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<String>? syncState,
    Expression<DateTime>? deletedAt,
    Expression<String>? companyId,
    Expression<int>? duplicateWindowMinutes,
    Expression<int>? staleOpenSessionMinutes,
    Expression<int>? excessiveDurationMinutes,
    Expression<int>? breakAfterMinutes,
    Expression<int>? breakMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (syncState != null) 'sync_state': syncState,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (companyId != null) 'company_id': companyId,
      if (duplicateWindowMinutes != null)
        'duplicate_window_minutes': duplicateWindowMinutes,
      if (staleOpenSessionMinutes != null)
        'stale_open_session_minutes': staleOpenSessionMinutes,
      if (excessiveDurationMinutes != null)
        'excessive_duration_minutes': excessiveDurationMinutes,
      if (breakAfterMinutes != null) 'break_after_minutes': breakAfterMinutes,
      if (breakMinutes != null) 'break_minutes': breakMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceSettingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<SyncState>? syncState,
    Value<DateTime?>? deletedAt,
    Value<String>? companyId,
    Value<int>? duplicateWindowMinutes,
    Value<int>? staleOpenSessionMinutes,
    Value<int>? excessiveDurationMinutes,
    Value<int?>? breakAfterMinutes,
    Value<int?>? breakMinutes,
    Value<int>? rowid,
  }) {
    return AttendanceSettingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      deletedAt: deletedAt ?? this.deletedAt,
      companyId: companyId ?? this.companyId,
      duplicateWindowMinutes:
          duplicateWindowMinutes ?? this.duplicateWindowMinutes,
      staleOpenSessionMinutes:
          staleOpenSessionMinutes ?? this.staleOpenSessionMinutes,
      excessiveDurationMinutes:
          excessiveDurationMinutes ?? this.excessiveDurationMinutes,
      breakAfterMinutes: breakAfterMinutes ?? this.breakAfterMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $AttendanceSettingsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (duplicateWindowMinutes.present) {
      map['duplicate_window_minutes'] = Variable<int>(
        duplicateWindowMinutes.value,
      );
    }
    if (staleOpenSessionMinutes.present) {
      map['stale_open_session_minutes'] = Variable<int>(
        staleOpenSessionMinutes.value,
      );
    }
    if (excessiveDurationMinutes.present) {
      map['excessive_duration_minutes'] = Variable<int>(
        excessiveDurationMinutes.value,
      );
    }
    if (breakAfterMinutes.present) {
      map['break_after_minutes'] = Variable<int>(breakAfterMinutes.value);
    }
    if (breakMinutes.present) {
      map['break_minutes'] = Variable<int>(breakMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceSettingsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('companyId: $companyId, ')
          ..write('duplicateWindowMinutes: $duplicateWindowMinutes, ')
          ..write('staleOpenSessionMinutes: $staleOpenSessionMinutes, ')
          ..write('excessiveDurationMinutes: $excessiveDurationMinutes, ')
          ..write('breakAfterMinutes: $breakAfterMinutes, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceCorrectionsTable extends AttendanceCorrections
    with TableInfo<$AttendanceCorrectionsTable, AttendanceCorrectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceCorrectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>(
        $AttendanceCorrectionsTable.$convertersyncState,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES employees (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalEventIdMeta = const VerificationMeta(
    'originalEventId',
  );
  @override
  late final GeneratedColumn<String> originalEventId = GeneratedColumn<String>(
    'original_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES attendance_events (id)',
    ),
  );
  static const VerificationMeta _replacementEventIdMeta =
      const VerificationMeta('replacementEventId');
  @override
  late final GeneratedColumn<String> replacementEventId =
      GeneratedColumn<String>(
        'replacement_event_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES attendance_events (id)',
        ),
      );
  static const VerificationMeta _previousOccurredAtMeta =
      const VerificationMeta('previousOccurredAt');
  @override
  late final GeneratedColumn<DateTime> previousOccurredAt =
      GeneratedColumn<DateTime>(
        'previous_occurred_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _newOccurredAtMeta = const VerificationMeta(
    'newOccurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> newOccurredAt =
      GeneratedColumn<DateTime>(
        'new_occurred_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctedByMeta = const VerificationMeta(
    'correctedBy',
  );
  @override
  late final GeneratedColumn<String> correctedBy = GeneratedColumn<String>(
    'corrected_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES admin_users (id)',
    ),
  );
  static const VerificationMeta _correctedAtMeta = const VerificationMeta(
    'correctedAt',
  );
  @override
  late final GeneratedColumn<DateTime> correctedAt = GeneratedColumn<DateTime>(
    'corrected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    employeeId,
    kind,
    eventType,
    originalEventId,
    replacementEventId,
    previousOccurredAt,
    newOccurredAt,
    reason,
    correctedBy,
    correctedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_corrections';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceCorrectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('original_event_id')) {
      context.handle(
        _originalEventIdMeta,
        originalEventId.isAcceptableOrUnknown(
          data['original_event_id']!,
          _originalEventIdMeta,
        ),
      );
    }
    if (data.containsKey('replacement_event_id')) {
      context.handle(
        _replacementEventIdMeta,
        replacementEventId.isAcceptableOrUnknown(
          data['replacement_event_id']!,
          _replacementEventIdMeta,
        ),
      );
    }
    if (data.containsKey('previous_occurred_at')) {
      context.handle(
        _previousOccurredAtMeta,
        previousOccurredAt.isAcceptableOrUnknown(
          data['previous_occurred_at']!,
          _previousOccurredAtMeta,
        ),
      );
    }
    if (data.containsKey('new_occurred_at')) {
      context.handle(
        _newOccurredAtMeta,
        newOccurredAt.isAcceptableOrUnknown(
          data['new_occurred_at']!,
          _newOccurredAtMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('corrected_by')) {
      context.handle(
        _correctedByMeta,
        correctedBy.isAcceptableOrUnknown(
          data['corrected_by']!,
          _correctedByMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctedByMeta);
    }
    if (data.containsKey('corrected_at')) {
      context.handle(
        _correctedAtMeta,
        correctedAt.isAcceptableOrUnknown(
          data['corrected_at']!,
          _correctedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceCorrectionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceCorrectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncState: $AttendanceCorrectionsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      originalEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_event_id'],
      ),
      replacementEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replacement_event_id'],
      ),
      previousOccurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}previous_occurred_at'],
      ),
      newOccurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}new_occurred_at'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      correctedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrected_by'],
      )!,
      correctedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}corrected_at'],
      )!,
    );
  }

  @override
  $AttendanceCorrectionsTable createAlias(String alias) {
    return $AttendanceCorrectionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class AttendanceCorrectionRow extends DataClass
    implements Insertable<AttendanceCorrectionRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final SyncState syncState;
  final DateTime? deletedAt;
  final String employeeId;

  /// `added`, `timeChanged` or `removed`.
  final String kind;

  /// `clockIn` or `clockOut`.
  final String eventType;
  final String? originalEventId;
  final String? replacementEventId;
  final DateTime? previousOccurredAt;
  final DateTime? newOccurredAt;
  final String reason;

  /// Administrator who made the correction.
  final String correctedBy;
  final DateTime correctedAt;
  const AttendanceCorrectionRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncState,
    this.deletedAt,
    required this.employeeId,
    required this.kind,
    required this.eventType,
    this.originalEventId,
    this.replacementEventId,
    this.previousOccurredAt,
    this.newOccurredAt,
    required this.reason,
    required this.correctedBy,
    required this.correctedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    {
      map['sync_state'] = Variable<String>(
        $AttendanceCorrectionsTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['employee_id'] = Variable<String>(employeeId);
    map['kind'] = Variable<String>(kind);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || originalEventId != null) {
      map['original_event_id'] = Variable<String>(originalEventId);
    }
    if (!nullToAbsent || replacementEventId != null) {
      map['replacement_event_id'] = Variable<String>(replacementEventId);
    }
    if (!nullToAbsent || previousOccurredAt != null) {
      map['previous_occurred_at'] = Variable<DateTime>(previousOccurredAt);
    }
    if (!nullToAbsent || newOccurredAt != null) {
      map['new_occurred_at'] = Variable<DateTime>(newOccurredAt);
    }
    map['reason'] = Variable<String>(reason);
    map['corrected_by'] = Variable<String>(correctedBy);
    map['corrected_at'] = Variable<DateTime>(correctedAt);
    return map;
  }

  AttendanceCorrectionsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceCorrectionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      syncState: Value(syncState),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      employeeId: Value(employeeId),
      kind: Value(kind),
      eventType: Value(eventType),
      originalEventId: originalEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalEventId),
      replacementEventId: replacementEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(replacementEventId),
      previousOccurredAt: previousOccurredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(previousOccurredAt),
      newOccurredAt: newOccurredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(newOccurredAt),
      reason: Value(reason),
      correctedBy: Value(correctedBy),
      correctedAt: Value(correctedAt),
    );
  }

  factory AttendanceCorrectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceCorrectionRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      syncState: $AttendanceCorrectionsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      kind: serializer.fromJson<String>(json['kind']),
      eventType: serializer.fromJson<String>(json['eventType']),
      originalEventId: serializer.fromJson<String?>(json['originalEventId']),
      replacementEventId: serializer.fromJson<String?>(
        json['replacementEventId'],
      ),
      previousOccurredAt: serializer.fromJson<DateTime?>(
        json['previousOccurredAt'],
      ),
      newOccurredAt: serializer.fromJson<DateTime?>(json['newOccurredAt']),
      reason: serializer.fromJson<String>(json['reason']),
      correctedBy: serializer.fromJson<String>(json['correctedBy']),
      correctedAt: serializer.fromJson<DateTime>(json['correctedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'syncState': serializer.toJson<String>(
        $AttendanceCorrectionsTable.$convertersyncState.toJson(syncState),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'employeeId': serializer.toJson<String>(employeeId),
      'kind': serializer.toJson<String>(kind),
      'eventType': serializer.toJson<String>(eventType),
      'originalEventId': serializer.toJson<String?>(originalEventId),
      'replacementEventId': serializer.toJson<String?>(replacementEventId),
      'previousOccurredAt': serializer.toJson<DateTime?>(previousOccurredAt),
      'newOccurredAt': serializer.toJson<DateTime?>(newOccurredAt),
      'reason': serializer.toJson<String>(reason),
      'correctedBy': serializer.toJson<String>(correctedBy),
      'correctedAt': serializer.toJson<DateTime>(correctedAt),
    };
  }

  AttendanceCorrectionRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    SyncState? syncState,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? employeeId,
    String? kind,
    String? eventType,
    Value<String?> originalEventId = const Value.absent(),
    Value<String?> replacementEventId = const Value.absent(),
    Value<DateTime?> previousOccurredAt = const Value.absent(),
    Value<DateTime?> newOccurredAt = const Value.absent(),
    String? reason,
    String? correctedBy,
    DateTime? correctedAt,
  }) => AttendanceCorrectionRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    syncState: syncState ?? this.syncState,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    employeeId: employeeId ?? this.employeeId,
    kind: kind ?? this.kind,
    eventType: eventType ?? this.eventType,
    originalEventId: originalEventId.present
        ? originalEventId.value
        : this.originalEventId,
    replacementEventId: replacementEventId.present
        ? replacementEventId.value
        : this.replacementEventId,
    previousOccurredAt: previousOccurredAt.present
        ? previousOccurredAt.value
        : this.previousOccurredAt,
    newOccurredAt: newOccurredAt.present
        ? newOccurredAt.value
        : this.newOccurredAt,
    reason: reason ?? this.reason,
    correctedBy: correctedBy ?? this.correctedBy,
    correctedAt: correctedAt ?? this.correctedAt,
  );
  AttendanceCorrectionRow copyWithCompanion(
    AttendanceCorrectionsCompanion data,
  ) {
    return AttendanceCorrectionRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      kind: data.kind.present ? data.kind.value : this.kind,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      originalEventId: data.originalEventId.present
          ? data.originalEventId.value
          : this.originalEventId,
      replacementEventId: data.replacementEventId.present
          ? data.replacementEventId.value
          : this.replacementEventId,
      previousOccurredAt: data.previousOccurredAt.present
          ? data.previousOccurredAt.value
          : this.previousOccurredAt,
      newOccurredAt: data.newOccurredAt.present
          ? data.newOccurredAt.value
          : this.newOccurredAt,
      reason: data.reason.present ? data.reason.value : this.reason,
      correctedBy: data.correctedBy.present
          ? data.correctedBy.value
          : this.correctedBy,
      correctedAt: data.correctedAt.present
          ? data.correctedAt.value
          : this.correctedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceCorrectionRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('employeeId: $employeeId, ')
          ..write('kind: $kind, ')
          ..write('eventType: $eventType, ')
          ..write('originalEventId: $originalEventId, ')
          ..write('replacementEventId: $replacementEventId, ')
          ..write('previousOccurredAt: $previousOccurredAt, ')
          ..write('newOccurredAt: $newOccurredAt, ')
          ..write('reason: $reason, ')
          ..write('correctedBy: $correctedBy, ')
          ..write('correctedAt: $correctedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    version,
    syncState,
    deletedAt,
    employeeId,
    kind,
    eventType,
    originalEventId,
    replacementEventId,
    previousOccurredAt,
    newOccurredAt,
    reason,
    correctedBy,
    correctedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceCorrectionRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.syncState == this.syncState &&
          other.deletedAt == this.deletedAt &&
          other.employeeId == this.employeeId &&
          other.kind == this.kind &&
          other.eventType == this.eventType &&
          other.originalEventId == this.originalEventId &&
          other.replacementEventId == this.replacementEventId &&
          other.previousOccurredAt == this.previousOccurredAt &&
          other.newOccurredAt == this.newOccurredAt &&
          other.reason == this.reason &&
          other.correctedBy == this.correctedBy &&
          other.correctedAt == this.correctedAt);
}

class AttendanceCorrectionsCompanion
    extends UpdateCompanion<AttendanceCorrectionRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<SyncState> syncState;
  final Value<DateTime?> deletedAt;
  final Value<String> employeeId;
  final Value<String> kind;
  final Value<String> eventType;
  final Value<String?> originalEventId;
  final Value<String?> replacementEventId;
  final Value<DateTime?> previousOccurredAt;
  final Value<DateTime?> newOccurredAt;
  final Value<String> reason;
  final Value<String> correctedBy;
  final Value<DateTime> correctedAt;
  final Value<int> rowid;
  const AttendanceCorrectionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.kind = const Value.absent(),
    this.eventType = const Value.absent(),
    this.originalEventId = const Value.absent(),
    this.replacementEventId = const Value.absent(),
    this.previousOccurredAt = const Value.absent(),
    this.newOccurredAt = const Value.absent(),
    this.reason = const Value.absent(),
    this.correctedBy = const Value.absent(),
    this.correctedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceCorrectionsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String employeeId,
    required String kind,
    required String eventType,
    this.originalEventId = const Value.absent(),
    this.replacementEventId = const Value.absent(),
    this.previousOccurredAt = const Value.absent(),
    this.newOccurredAt = const Value.absent(),
    required String reason,
    required String correctedBy,
    required DateTime correctedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       employeeId = Value(employeeId),
       kind = Value(kind),
       eventType = Value(eventType),
       reason = Value(reason),
       correctedBy = Value(correctedBy),
       correctedAt = Value(correctedAt);
  static Insertable<AttendanceCorrectionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<String>? syncState,
    Expression<DateTime>? deletedAt,
    Expression<String>? employeeId,
    Expression<String>? kind,
    Expression<String>? eventType,
    Expression<String>? originalEventId,
    Expression<String>? replacementEventId,
    Expression<DateTime>? previousOccurredAt,
    Expression<DateTime>? newOccurredAt,
    Expression<String>? reason,
    Expression<String>? correctedBy,
    Expression<DateTime>? correctedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (syncState != null) 'sync_state': syncState,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (employeeId != null) 'employee_id': employeeId,
      if (kind != null) 'kind': kind,
      if (eventType != null) 'event_type': eventType,
      if (originalEventId != null) 'original_event_id': originalEventId,
      if (replacementEventId != null)
        'replacement_event_id': replacementEventId,
      if (previousOccurredAt != null)
        'previous_occurred_at': previousOccurredAt,
      if (newOccurredAt != null) 'new_occurred_at': newOccurredAt,
      if (reason != null) 'reason': reason,
      if (correctedBy != null) 'corrected_by': correctedBy,
      if (correctedAt != null) 'corrected_at': correctedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceCorrectionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<SyncState>? syncState,
    Value<DateTime?>? deletedAt,
    Value<String>? employeeId,
    Value<String>? kind,
    Value<String>? eventType,
    Value<String?>? originalEventId,
    Value<String?>? replacementEventId,
    Value<DateTime?>? previousOccurredAt,
    Value<DateTime?>? newOccurredAt,
    Value<String>? reason,
    Value<String>? correctedBy,
    Value<DateTime>? correctedAt,
    Value<int>? rowid,
  }) {
    return AttendanceCorrectionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      deletedAt: deletedAt ?? this.deletedAt,
      employeeId: employeeId ?? this.employeeId,
      kind: kind ?? this.kind,
      eventType: eventType ?? this.eventType,
      originalEventId: originalEventId ?? this.originalEventId,
      replacementEventId: replacementEventId ?? this.replacementEventId,
      previousOccurredAt: previousOccurredAt ?? this.previousOccurredAt,
      newOccurredAt: newOccurredAt ?? this.newOccurredAt,
      reason: reason ?? this.reason,
      correctedBy: correctedBy ?? this.correctedBy,
      correctedAt: correctedAt ?? this.correctedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $AttendanceCorrectionsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (originalEventId.present) {
      map['original_event_id'] = Variable<String>(originalEventId.value);
    }
    if (replacementEventId.present) {
      map['replacement_event_id'] = Variable<String>(replacementEventId.value);
    }
    if (previousOccurredAt.present) {
      map['previous_occurred_at'] = Variable<DateTime>(
        previousOccurredAt.value,
      );
    }
    if (newOccurredAt.present) {
      map['new_occurred_at'] = Variable<DateTime>(newOccurredAt.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (correctedBy.present) {
      map['corrected_by'] = Variable<String>(correctedBy.value);
    }
    if (correctedAt.present) {
      map['corrected_at'] = Variable<DateTime>(correctedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceCorrectionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('employeeId: $employeeId, ')
          ..write('kind: $kind, ')
          ..write('eventType: $eventType, ')
          ..write('originalEventId: $originalEventId, ')
          ..write('replacementEventId: $replacementEventId, ')
          ..write('previousOccurredAt: $previousOccurredAt, ')
          ..write('newOccurredAt: $newOccurredAt, ')
          ..write('reason: $reason, ')
          ..write('correctedBy: $correctedBy, ')
          ..write('correctedAt: $correctedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceSettingsTable extends DeviceSettings
    with TableInfo<$DeviceSettingsTable, DeviceSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kioskCompanyIdMeta = const VerificationMeta(
    'kioskCompanyId',
  );
  @override
  late final GeneratedColumn<String> kioskCompanyId = GeneratedColumn<String>(
    'kiosk_company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES companies (id)',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, kioskCompanyId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kiosk_company_id')) {
      context.handle(
        _kioskCompanyIdMeta,
        kioskCompanyId.isAcceptableOrUnknown(
          data['kiosk_company_id']!,
          _kioskCompanyIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kioskCompanyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kiosk_company_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DeviceSettingsTable createAlias(String alias) {
    return $DeviceSettingsTable(attachedDatabase, alias);
  }
}

class DeviceSettingsRow extends DataClass
    implements Insertable<DeviceSettingsRow> {
  final String id;

  /// The company whose employees use this device as an attendance kiosk, or
  /// null when kiosk mode is off.
  final String? kioskCompanyId;
  final DateTime updatedAt;
  const DeviceSettingsRow({
    required this.id,
    this.kioskCompanyId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || kioskCompanyId != null) {
      map['kiosk_company_id'] = Variable<String>(kioskCompanyId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeviceSettingsCompanion toCompanion(bool nullToAbsent) {
    return DeviceSettingsCompanion(
      id: Value(id),
      kioskCompanyId: kioskCompanyId == null && nullToAbsent
          ? const Value.absent()
          : Value(kioskCompanyId),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeviceSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceSettingsRow(
      id: serializer.fromJson<String>(json['id']),
      kioskCompanyId: serializer.fromJson<String?>(json['kioskCompanyId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kioskCompanyId': serializer.toJson<String?>(kioskCompanyId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeviceSettingsRow copyWith({
    String? id,
    Value<String?> kioskCompanyId = const Value.absent(),
    DateTime? updatedAt,
  }) => DeviceSettingsRow(
    id: id ?? this.id,
    kioskCompanyId: kioskCompanyId.present
        ? kioskCompanyId.value
        : this.kioskCompanyId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DeviceSettingsRow copyWithCompanion(DeviceSettingsCompanion data) {
    return DeviceSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      kioskCompanyId: data.kioskCompanyId.present
          ? data.kioskCompanyId.value
          : this.kioskCompanyId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSettingsRow(')
          ..write('id: $id, ')
          ..write('kioskCompanyId: $kioskCompanyId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kioskCompanyId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceSettingsRow &&
          other.id == this.id &&
          other.kioskCompanyId == this.kioskCompanyId &&
          other.updatedAt == this.updatedAt);
}

class DeviceSettingsCompanion extends UpdateCompanion<DeviceSettingsRow> {
  final Value<String> id;
  final Value<String?> kioskCompanyId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DeviceSettingsCompanion({
    this.id = const Value.absent(),
    this.kioskCompanyId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceSettingsCompanion.insert({
    required String id,
    this.kioskCompanyId = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt);
  static Insertable<DeviceSettingsRow> custom({
    Expression<String>? id,
    Expression<String>? kioskCompanyId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kioskCompanyId != null) 'kiosk_company_id': kioskCompanyId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceSettingsCompanion copyWith({
    Value<String>? id,
    Value<String?>? kioskCompanyId,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DeviceSettingsCompanion(
      id: id ?? this.id,
      kioskCompanyId: kioskCompanyId ?? this.kioskCompanyId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kioskCompanyId.present) {
      map['kiosk_company_id'] = Variable<String>(kioskCompanyId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSettingsCompanion(')
          ..write('id: $id, ')
          ..write('kioskCompanyId: $kioskCompanyId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CompaniesTable companies = $CompaniesTable(this);
  late final $AdminUsersTable adminUsers = $AdminUsersTable(this);
  late final $EmployeesTable employees = $EmployeesTable(this);
  late final $EmployeeRatesTable employeeRates = $EmployeeRatesTable(this);
  late final $CredentialsTable credentials = $CredentialsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $DeviceIdentityTable deviceIdentity = $DeviceIdentityTable(this);
  late final $AttendanceEventsTable attendanceEvents = $AttendanceEventsTable(
    this,
  );
  late final $AttendanceSettingsTable attendanceSettings =
      $AttendanceSettingsTable(this);
  late final $AttendanceCorrectionsTable attendanceCorrections =
      $AttendanceCorrectionsTable(this);
  late final $DeviceSettingsTable deviceSettings = $DeviceSettingsTable(this);
  late final Index auditLogCompanyTime = Index(
    'audit_log_company_time',
    'CREATE INDEX audit_log_company_time ON audit_log (company_id, occurred_at)',
  );
  late final Index auditLogEntity = Index(
    'audit_log_entity',
    'CREATE INDEX audit_log_entity ON audit_log (entity_type, entity_id)',
  );
  late final Index attendanceEventsEmployeeTime = Index(
    'attendance_events_employee_time',
    'CREATE INDEX attendance_events_employee_time ON attendance_events (employee_id, occurred_at)',
  );
  late final Index attendanceEventsTime = Index(
    'attendance_events_time',
    'CREATE INDEX attendance_events_time ON attendance_events (occurred_at)',
  );
  late final Index attendanceCorrectionsOriginal = Index(
    'attendance_corrections_original',
    'CREATE INDEX attendance_corrections_original ON attendance_corrections (original_event_id)',
  );
  late final Index attendanceCorrectionsEmployee = Index(
    'attendance_corrections_employee',
    'CREATE INDEX attendance_corrections_employee ON attendance_corrections (employee_id, corrected_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    companies,
    adminUsers,
    employees,
    employeeRates,
    credentials,
    auditLog,
    deviceIdentity,
    attendanceEvents,
    attendanceSettings,
    attendanceCorrections,
    deviceSettings,
    auditLogCompanyTime,
    auditLogEntity,
    attendanceEventsEmployeeTime,
    attendanceEventsTime,
    attendanceCorrectionsOriginal,
    attendanceCorrectionsEmployee,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CompaniesTableCreateCompanionBuilder =
    CompaniesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      required String name,
      Value<String?> legalName,
      Value<String?> registrationNumber,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      required String currencyCode,
      required String timezone,
      Value<String?> logoPath,
      Value<int> rowid,
    });
typedef $$CompaniesTableUpdateCompanionBuilder =
    CompaniesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<String?> legalName,
      Value<String?> registrationNumber,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<String> currencyCode,
      Value<String> timezone,
      Value<String?> logoPath,
      Value<int> rowid,
    });

final class $$CompaniesTableReferences
    extends BaseReferences<_$AppDatabase, $CompaniesTable, CompanyRow> {
  $$CompaniesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AdminUsersTable, List<AdminUserRow>>
  _adminUsersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.adminUsers,
    aliasName: 'companies__id__admin_users__company_id',
  );

  $$AdminUsersTableProcessedTableManager get adminUsersRefs {
    final manager = $$AdminUsersTableTableManager(
      $_db,
      $_db.adminUsers,
    ).filter((f) => f.companyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_adminUsersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EmployeesTable, List<EmployeeRow>>
  _employeesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.employees,
    aliasName: 'companies__id__employees__company_id',
  );

  $$EmployeesTableProcessedTableManager get employeesRefs {
    final manager = $$EmployeesTableTableManager(
      $_db,
      $_db.employees,
    ).filter((f) => f.companyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_employeesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AuditLogTable, List<AuditLogRow>>
  _auditLogRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.auditLog,
    aliasName: 'companies__id__audit_log__company_id',
  );

  $$AuditLogTableProcessedTableManager get auditLogRefs {
    final manager = $$AuditLogTableTableManager(
      $_db,
      $_db.auditLog,
    ).filter((f) => f.companyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_auditLogRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AttendanceSettingsTable,
    List<AttendanceSettingsRow>
  >
  _attendanceSettingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceSettings,
        aliasName: 'companies__id__attendance_settings__company_id',
      );

  $$AttendanceSettingsTableProcessedTableManager get attendanceSettingsRefs {
    final manager = $$AttendanceSettingsTableTableManager(
      $_db,
      $_db.attendanceSettings,
    ).filter((f) => f.companyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DeviceSettingsTable, List<DeviceSettingsRow>>
  _deviceSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.deviceSettings,
    aliasName: 'companies__id__device_settings__kiosk_company_id',
  );

  $$DeviceSettingsTableProcessedTableManager get deviceSettingsRefs {
    final manager = $$DeviceSettingsTableTableManager(
      $_db,
      $_db.deviceSettings,
    ).filter((f) => f.kioskCompanyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_deviceSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompaniesTableFilterComposer
    extends Composer<_$AppDatabase, $CompaniesTable> {
  $$CompaniesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> adminUsersRefs(
    Expression<bool> Function($$AdminUsersTableFilterComposer f) f,
  ) {
    final $$AdminUsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adminUsers,
      getReferencedColumn: (t) => t.companyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdminUsersTableFilterComposer(
            $db: $db,
            $table: $db.adminUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> employeesRefs(
    Expression<bool> Function($$EmployeesTableFilterComposer f) f,
  ) {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.companyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableFilterComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> auditLogRefs(
    Expression<bool> Function($$AuditLogTableFilterComposer f) f,
  ) {
    final $$AuditLogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.auditLog,
      getReferencedColumn: (t) => t.companyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuditLogTableFilterComposer(
            $db: $db,
            $table: $db.auditLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attendanceSettingsRefs(
    Expression<bool> Function($$AttendanceSettingsTableFilterComposer f) f,
  ) {
    final $$AttendanceSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attendanceSettings,
      getReferencedColumn: (t) => t.companyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceSettingsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> deviceSettingsRefs(
    Expression<bool> Function($$DeviceSettingsTableFilterComposer f) f,
  ) {
    final $$DeviceSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deviceSettings,
      getReferencedColumn: (t) => t.kioskCompanyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeviceSettingsTableFilterComposer(
            $db: $db,
            $table: $db.deviceSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompaniesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompaniesTable> {
  $$CompaniesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompaniesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompaniesTable> {
  $$CompaniesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get legalName =>
      $composableBuilder(column: $table.legalName, builder: (column) => column);

  GeneratedColumn<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  Expression<T> adminUsersRefs<T extends Object>(
    Expression<T> Function($$AdminUsersTableAnnotationComposer a) f,
  ) {
    final $$AdminUsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adminUsers,
      getReferencedColumn: (t) => t.companyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdminUsersTableAnnotationComposer(
            $db: $db,
            $table: $db.adminUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> employeesRefs<T extends Object>(
    Expression<T> Function($$EmployeesTableAnnotationComposer a) f,
  ) {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.companyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableAnnotationComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> auditLogRefs<T extends Object>(
    Expression<T> Function($$AuditLogTableAnnotationComposer a) f,
  ) {
    final $$AuditLogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.auditLog,
      getReferencedColumn: (t) => t.companyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuditLogTableAnnotationComposer(
            $db: $db,
            $table: $db.auditLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attendanceSettingsRefs<T extends Object>(
    Expression<T> Function($$AttendanceSettingsTableAnnotationComposer a) f,
  ) {
    final $$AttendanceSettingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceSettings,
          getReferencedColumn: (t) => t.companyId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceSettingsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> deviceSettingsRefs<T extends Object>(
    Expression<T> Function($$DeviceSettingsTableAnnotationComposer a) f,
  ) {
    final $$DeviceSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deviceSettings,
      getReferencedColumn: (t) => t.kioskCompanyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeviceSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.deviceSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompaniesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompaniesTable,
          CompanyRow,
          $$CompaniesTableFilterComposer,
          $$CompaniesTableOrderingComposer,
          $$CompaniesTableAnnotationComposer,
          $$CompaniesTableCreateCompanionBuilder,
          $$CompaniesTableUpdateCompanionBuilder,
          (CompanyRow, $$CompaniesTableReferences),
          CompanyRow,
          PrefetchHooks Function({
            bool adminUsersRefs,
            bool employeesRefs,
            bool auditLogRefs,
            bool attendanceSettingsRefs,
            bool deviceSettingsRefs,
          })
        > {
  $$CompaniesTableTableManager(_$AppDatabase db, $CompaniesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompaniesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompaniesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompaniesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> legalName = const Value.absent(),
                Value<String?> registrationNumber = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompaniesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                name: name,
                legalName: legalName,
                registrationNumber: registrationNumber,
                phone: phone,
                email: email,
                address: address,
                currencyCode: currencyCode,
                timezone: timezone,
                logoPath: logoPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<String?> legalName = const Value.absent(),
                Value<String?> registrationNumber = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                required String currencyCode,
                required String timezone,
                Value<String?> logoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompaniesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                name: name,
                legalName: legalName,
                registrationNumber: registrationNumber,
                phone: phone,
                email: email,
                address: address,
                currencyCode: currencyCode,
                timezone: timezone,
                logoPath: logoPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CompaniesTable, CompanyRow>(table),
                  $$CompaniesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                adminUsersRefs = false,
                employeesRefs = false,
                auditLogRefs = false,
                attendanceSettingsRefs = false,
                deviceSettingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (adminUsersRefs) db.adminUsers,
                    if (employeesRefs) db.employees,
                    if (auditLogRefs) db.auditLog,
                    if (attendanceSettingsRefs) db.attendanceSettings,
                    if (deviceSettingsRefs) db.deviceSettings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (adminUsersRefs)
                        await $_getPrefetchedData<
                          CompanyRow,
                          $CompaniesTable,
                          AdminUserRow
                        >(
                          currentTable: table,
                          referencedTable: $$CompaniesTableReferences
                              ._adminUsersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompaniesTableReferences(
                                db,
                                table,
                                p0,
                              ).adminUsersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.companyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (employeesRefs)
                        await $_getPrefetchedData<
                          CompanyRow,
                          $CompaniesTable,
                          EmployeeRow
                        >(
                          currentTable: table,
                          referencedTable: $$CompaniesTableReferences
                              ._employeesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompaniesTableReferences(
                                db,
                                table,
                                p0,
                              ).employeesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.companyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (auditLogRefs)
                        await $_getPrefetchedData<
                          CompanyRow,
                          $CompaniesTable,
                          AuditLogRow
                        >(
                          currentTable: table,
                          referencedTable: $$CompaniesTableReferences
                              ._auditLogRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompaniesTableReferences(
                                db,
                                table,
                                p0,
                              ).auditLogRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.companyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attendanceSettingsRefs)
                        await $_getPrefetchedData<
                          CompanyRow,
                          $CompaniesTable,
                          AttendanceSettingsRow
                        >(
                          currentTable: table,
                          referencedTable: $$CompaniesTableReferences
                              ._attendanceSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompaniesTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.companyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (deviceSettingsRefs)
                        await $_getPrefetchedData<
                          CompanyRow,
                          $CompaniesTable,
                          DeviceSettingsRow
                        >(
                          currentTable: table,
                          referencedTable: $$CompaniesTableReferences
                              ._deviceSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompaniesTableReferences(
                                db,
                                table,
                                p0,
                              ).deviceSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.kioskCompanyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CompaniesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompaniesTable,
      CompanyRow,
      $$CompaniesTableFilterComposer,
      $$CompaniesTableOrderingComposer,
      $$CompaniesTableAnnotationComposer,
      $$CompaniesTableCreateCompanionBuilder,
      $$CompaniesTableUpdateCompanionBuilder,
      (CompanyRow, $$CompaniesTableReferences),
      CompanyRow,
      PrefetchHooks Function({
        bool adminUsersRefs,
        bool employeesRefs,
        bool auditLogRefs,
        bool attendanceSettingsRefs,
        bool deviceSettingsRefs,
      })
    >;
typedef $$AdminUsersTableCreateCompanionBuilder =
    AdminUsersCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      required String companyId,
      required String username,
      required String displayName,
      required String role,
      Value<bool> active,
      Value<DateTime?> lastLoginAt,
      Value<int> rowid,
    });
typedef $$AdminUsersTableUpdateCompanionBuilder =
    AdminUsersCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      Value<String> companyId,
      Value<String> username,
      Value<String> displayName,
      Value<String> role,
      Value<bool> active,
      Value<DateTime?> lastLoginAt,
      Value<int> rowid,
    });

final class $$AdminUsersTableReferences
    extends BaseReferences<_$AppDatabase, $AdminUsersTable, AdminUserRow> {
  $$AdminUsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CompaniesTable _companyIdTable(_$AppDatabase db) =>
      db.companies.createAlias('admin_users__company_id__companies__id');

  $$CompaniesTableProcessedTableManager get companyId {
    final $_column = $_itemColumn<String>('company_id')!;

    final manager = $$CompaniesTableTableManager(
      $_db,
      $_db.companies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_companyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CredentialsTable, List<CredentialRow>>
  _credentialsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.credentials,
    aliasName: 'admin_users__id__credentials__admin_user_id',
  );

  $$CredentialsTableProcessedTableManager get credentialsRefs {
    final manager = $$CredentialsTableTableManager(
      $_db,
      $_db.credentials,
    ).filter((f) => f.adminUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_credentialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AttendanceCorrectionsTable,
    List<AttendanceCorrectionRow>
  >
  _attendanceCorrectionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceCorrections,
        aliasName: 'admin_users__id__attendance_corrections__corrected_by',
      );

  $$AttendanceCorrectionsTableProcessedTableManager
  get attendanceCorrectionsRefs {
    final manager = $$AttendanceCorrectionsTableTableManager(
      $_db,
      $_db.attendanceCorrections,
    ).filter((f) => f.correctedBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceCorrectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AdminUsersTableFilterComposer
    extends Composer<_$AppDatabase, $AdminUsersTable> {
  $$AdminUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CompaniesTableFilterComposer get companyId {
    final $$CompaniesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableFilterComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> credentialsRefs(
    Expression<bool> Function($$CredentialsTableFilterComposer f) f,
  ) {
    final $$CredentialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.adminUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableFilterComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attendanceCorrectionsRefs(
    Expression<bool> Function($$AttendanceCorrectionsTableFilterComposer f) f,
  ) {
    final $$AttendanceCorrectionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceCorrections,
          getReferencedColumn: (t) => t.correctedBy,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceCorrectionsTableFilterComposer(
                $db: $db,
                $table: $db.attendanceCorrections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AdminUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $AdminUsersTable> {
  $$AdminUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompaniesTableOrderingComposer get companyId {
    final $$CompaniesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableOrderingComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdminUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdminUsersTable> {
  $$AdminUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => column,
  );

  $$CompaniesTableAnnotationComposer get companyId {
    final $$CompaniesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableAnnotationComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> credentialsRefs<T extends Object>(
    Expression<T> Function($$CredentialsTableAnnotationComposer a) f,
  ) {
    final $$CredentialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.adminUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attendanceCorrectionsRefs<T extends Object>(
    Expression<T> Function($$AttendanceCorrectionsTableAnnotationComposer a) f,
  ) {
    final $$AttendanceCorrectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceCorrections,
          getReferencedColumn: (t) => t.correctedBy,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceCorrectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceCorrections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AdminUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdminUsersTable,
          AdminUserRow,
          $$AdminUsersTableFilterComposer,
          $$AdminUsersTableOrderingComposer,
          $$AdminUsersTableAnnotationComposer,
          $$AdminUsersTableCreateCompanionBuilder,
          $$AdminUsersTableUpdateCompanionBuilder,
          (AdminUserRow, $$AdminUsersTableReferences),
          AdminUserRow,
          PrefetchHooks Function({
            bool companyId,
            bool credentialsRefs,
            bool attendanceCorrectionsRefs,
          })
        > {
  $$AdminUsersTableTableManager(_$AppDatabase db, $AdminUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdminUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdminUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdminUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime?> lastLoginAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdminUsersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                companyId: companyId,
                username: username,
                displayName: displayName,
                role: role,
                active: active,
                lastLoginAt: lastLoginAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String companyId,
                required String username,
                required String displayName,
                required String role,
                Value<bool> active = const Value.absent(),
                Value<DateTime?> lastLoginAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdminUsersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                companyId: companyId,
                username: username,
                displayName: displayName,
                role: role,
                active: active,
                lastLoginAt: lastLoginAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AdminUsersTable, AdminUserRow>(table),
                  $$AdminUsersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                companyId = false,
                credentialsRefs = false,
                attendanceCorrectionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (credentialsRefs) db.credentials,
                    if (attendanceCorrectionsRefs) db.attendanceCorrections,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (companyId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.companyId,
                                    referencedTable: $$AdminUsersTableReferences
                                        ._companyIdTable(db),
                                    referencedColumn:
                                        $$AdminUsersTableReferences
                                            ._companyIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (credentialsRefs)
                        await $_getPrefetchedData<
                          AdminUserRow,
                          $AdminUsersTable,
                          CredentialRow
                        >(
                          currentTable: table,
                          referencedTable: $$AdminUsersTableReferences
                              ._credentialsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AdminUsersTableReferences(
                                db,
                                table,
                                p0,
                              ).credentialsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.adminUserId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attendanceCorrectionsRefs)
                        await $_getPrefetchedData<
                          AdminUserRow,
                          $AdminUsersTable,
                          AttendanceCorrectionRow
                        >(
                          currentTable: table,
                          referencedTable: $$AdminUsersTableReferences
                              ._attendanceCorrectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AdminUsersTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceCorrectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.correctedBy == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AdminUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdminUsersTable,
      AdminUserRow,
      $$AdminUsersTableFilterComposer,
      $$AdminUsersTableOrderingComposer,
      $$AdminUsersTableAnnotationComposer,
      $$AdminUsersTableCreateCompanionBuilder,
      $$AdminUsersTableUpdateCompanionBuilder,
      (AdminUserRow, $$AdminUsersTableReferences),
      AdminUserRow,
      PrefetchHooks Function({
        bool companyId,
        bool credentialsRefs,
        bool attendanceCorrectionsRefs,
      })
    >;
typedef $$EmployeesTableCreateCompanionBuilder =
    EmployeesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      required String companyId,
      required String employeeNumber,
      required String firstName,
      Value<String?> middleName,
      required String lastName,
      Value<String?> displayName,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> jobTitle,
      required String employmentStatus,
      required LocalDate employmentStartDate,
      Value<LocalDate?> employmentEndDate,
      Value<int> rowid,
    });
typedef $$EmployeesTableUpdateCompanionBuilder =
    EmployeesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      Value<String> companyId,
      Value<String> employeeNumber,
      Value<String> firstName,
      Value<String?> middleName,
      Value<String> lastName,
      Value<String?> displayName,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> jobTitle,
      Value<String> employmentStatus,
      Value<LocalDate> employmentStartDate,
      Value<LocalDate?> employmentEndDate,
      Value<int> rowid,
    });

final class $$EmployeesTableReferences
    extends BaseReferences<_$AppDatabase, $EmployeesTable, EmployeeRow> {
  $$EmployeesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CompaniesTable _companyIdTable(_$AppDatabase db) =>
      db.companies.createAlias('employees__company_id__companies__id');

  $$CompaniesTableProcessedTableManager get companyId {
    final $_column = $_itemColumn<String>('company_id')!;

    final manager = $$CompaniesTableTableManager(
      $_db,
      $_db.companies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_companyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EmployeeRatesTable, List<EmployeeRateRow>>
  _employeeRatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.employeeRates,
    aliasName: 'employees__id__employee_rates__employee_id',
  );

  $$EmployeeRatesTableProcessedTableManager get employeeRatesRefs {
    final manager = $$EmployeeRatesTableTableManager(
      $_db,
      $_db.employeeRates,
    ).filter((f) => f.employeeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_employeeRatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CredentialsTable, List<CredentialRow>>
  _credentialsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.credentials,
    aliasName: 'employees__id__credentials__employee_id',
  );

  $$CredentialsTableProcessedTableManager get credentialsRefs {
    final manager = $$CredentialsTableTableManager(
      $_db,
      $_db.credentials,
    ).filter((f) => f.employeeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_credentialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttendanceEventsTable, List<AttendanceEventRow>>
  _attendanceEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attendanceEvents,
    aliasName: 'employees__id__attendance_events__employee_id',
  );

  $$AttendanceEventsTableProcessedTableManager get attendanceEventsRefs {
    final manager = $$AttendanceEventsTableTableManager(
      $_db,
      $_db.attendanceEvents,
    ).filter((f) => f.employeeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AttendanceCorrectionsTable,
    List<AttendanceCorrectionRow>
  >
  _attendanceCorrectionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceCorrections,
        aliasName: 'employees__id__attendance_corrections__employee_id',
      );

  $$AttendanceCorrectionsTableProcessedTableManager
  get attendanceCorrectionsRefs {
    final manager = $$AttendanceCorrectionsTableTableManager(
      $_db,
      $_db.attendanceCorrections,
    ).filter((f) => f.employeeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceCorrectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EmployeesTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeNumber => $composableBuilder(
    column: $table.employeeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobTitle => $composableBuilder(
    column: $table.jobTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employmentStatus => $composableBuilder(
    column: $table.employmentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String>
  get employmentStartDate => $composableBuilder(
    column: $table.employmentStartDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String>
  get employmentEndDate => $composableBuilder(
    column: $table.employmentEndDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$CompaniesTableFilterComposer get companyId {
    final $$CompaniesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableFilterComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> employeeRatesRefs(
    Expression<bool> Function($$EmployeeRatesTableFilterComposer f) f,
  ) {
    final $$EmployeeRatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.employeeRates,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeeRatesTableFilterComposer(
            $db: $db,
            $table: $db.employeeRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> credentialsRefs(
    Expression<bool> Function($$CredentialsTableFilterComposer f) f,
  ) {
    final $$CredentialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableFilterComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attendanceEventsRefs(
    Expression<bool> Function($$AttendanceEventsTableFilterComposer f) f,
  ) {
    final $$AttendanceEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attendanceEvents,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceEventsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attendanceCorrectionsRefs(
    Expression<bool> Function($$AttendanceCorrectionsTableFilterComposer f) f,
  ) {
    final $$AttendanceCorrectionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceCorrections,
          getReferencedColumn: (t) => t.employeeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceCorrectionsTableFilterComposer(
                $db: $db,
                $table: $db.attendanceCorrections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EmployeesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeNumber => $composableBuilder(
    column: $table.employeeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobTitle => $composableBuilder(
    column: $table.jobTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employmentStatus => $composableBuilder(
    column: $table.employmentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employmentStartDate => $composableBuilder(
    column: $table.employmentStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employmentEndDate => $composableBuilder(
    column: $table.employmentEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompaniesTableOrderingComposer get companyId {
    final $$CompaniesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableOrderingComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmployeesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get employeeNumber => $composableBuilder(
    column: $table.employeeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get jobTitle =>
      $composableBuilder(column: $table.jobTitle, builder: (column) => column);

  GeneratedColumn<String> get employmentStatus => $composableBuilder(
    column: $table.employmentStatus,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LocalDate, String> get employmentStartDate =>
      $composableBuilder(
        column: $table.employmentStartDate,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<LocalDate?, String> get employmentEndDate =>
      $composableBuilder(
        column: $table.employmentEndDate,
        builder: (column) => column,
      );

  $$CompaniesTableAnnotationComposer get companyId {
    final $$CompaniesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableAnnotationComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> employeeRatesRefs<T extends Object>(
    Expression<T> Function($$EmployeeRatesTableAnnotationComposer a) f,
  ) {
    final $$EmployeeRatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.employeeRates,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeeRatesTableAnnotationComposer(
            $db: $db,
            $table: $db.employeeRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> credentialsRefs<T extends Object>(
    Expression<T> Function($$CredentialsTableAnnotationComposer a) f,
  ) {
    final $$CredentialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attendanceEventsRefs<T extends Object>(
    Expression<T> Function($$AttendanceEventsTableAnnotationComposer a) f,
  ) {
    final $$AttendanceEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attendanceEvents,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.attendanceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attendanceCorrectionsRefs<T extends Object>(
    Expression<T> Function($$AttendanceCorrectionsTableAnnotationComposer a) f,
  ) {
    final $$AttendanceCorrectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceCorrections,
          getReferencedColumn: (t) => t.employeeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceCorrectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceCorrections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EmployeesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployeesTable,
          EmployeeRow,
          $$EmployeesTableFilterComposer,
          $$EmployeesTableOrderingComposer,
          $$EmployeesTableAnnotationComposer,
          $$EmployeesTableCreateCompanionBuilder,
          $$EmployeesTableUpdateCompanionBuilder,
          (EmployeeRow, $$EmployeesTableReferences),
          EmployeeRow,
          PrefetchHooks Function({
            bool companyId,
            bool employeeRatesRefs,
            bool credentialsRefs,
            bool attendanceEventsRefs,
            bool attendanceCorrectionsRefs,
          })
        > {
  $$EmployeesTableTableManager(_$AppDatabase db, $EmployeesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> employeeNumber = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String?> middleName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> jobTitle = const Value.absent(),
                Value<String> employmentStatus = const Value.absent(),
                Value<LocalDate> employmentStartDate = const Value.absent(),
                Value<LocalDate?> employmentEndDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                companyId: companyId,
                employeeNumber: employeeNumber,
                firstName: firstName,
                middleName: middleName,
                lastName: lastName,
                displayName: displayName,
                phone: phone,
                email: email,
                jobTitle: jobTitle,
                employmentStatus: employmentStatus,
                employmentStartDate: employmentStartDate,
                employmentEndDate: employmentEndDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String companyId,
                required String employeeNumber,
                required String firstName,
                Value<String?> middleName = const Value.absent(),
                required String lastName,
                Value<String?> displayName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> jobTitle = const Value.absent(),
                required String employmentStatus,
                required LocalDate employmentStartDate,
                Value<LocalDate?> employmentEndDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                companyId: companyId,
                employeeNumber: employeeNumber,
                firstName: firstName,
                middleName: middleName,
                lastName: lastName,
                displayName: displayName,
                phone: phone,
                email: email,
                jobTitle: jobTitle,
                employmentStatus: employmentStatus,
                employmentStartDate: employmentStartDate,
                employmentEndDate: employmentEndDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EmployeesTable, EmployeeRow>(table),
                  $$EmployeesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                companyId = false,
                employeeRatesRefs = false,
                credentialsRefs = false,
                attendanceEventsRefs = false,
                attendanceCorrectionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (employeeRatesRefs) db.employeeRates,
                    if (credentialsRefs) db.credentials,
                    if (attendanceEventsRefs) db.attendanceEvents,
                    if (attendanceCorrectionsRefs) db.attendanceCorrections,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (companyId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.companyId,
                                    referencedTable: $$EmployeesTableReferences
                                        ._companyIdTable(db),
                                    referencedColumn: $$EmployeesTableReferences
                                        ._companyIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (employeeRatesRefs)
                        await $_getPrefetchedData<
                          EmployeeRow,
                          $EmployeesTable,
                          EmployeeRateRow
                        >(
                          currentTable: table,
                          referencedTable: $$EmployeesTableReferences
                              ._employeeRatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmployeesTableReferences(
                                db,
                                table,
                                p0,
                              ).employeeRatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.employeeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (credentialsRefs)
                        await $_getPrefetchedData<
                          EmployeeRow,
                          $EmployeesTable,
                          CredentialRow
                        >(
                          currentTable: table,
                          referencedTable: $$EmployeesTableReferences
                              ._credentialsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmployeesTableReferences(
                                db,
                                table,
                                p0,
                              ).credentialsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.employeeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attendanceEventsRefs)
                        await $_getPrefetchedData<
                          EmployeeRow,
                          $EmployeesTable,
                          AttendanceEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$EmployeesTableReferences
                              ._attendanceEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmployeesTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.employeeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attendanceCorrectionsRefs)
                        await $_getPrefetchedData<
                          EmployeeRow,
                          $EmployeesTable,
                          AttendanceCorrectionRow
                        >(
                          currentTable: table,
                          referencedTable: $$EmployeesTableReferences
                              ._attendanceCorrectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmployeesTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceCorrectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.employeeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EmployeesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployeesTable,
      EmployeeRow,
      $$EmployeesTableFilterComposer,
      $$EmployeesTableOrderingComposer,
      $$EmployeesTableAnnotationComposer,
      $$EmployeesTableCreateCompanionBuilder,
      $$EmployeesTableUpdateCompanionBuilder,
      (EmployeeRow, $$EmployeesTableReferences),
      EmployeeRow,
      PrefetchHooks Function({
        bool companyId,
        bool employeeRatesRefs,
        bool credentialsRefs,
        bool attendanceEventsRefs,
        bool attendanceCorrectionsRefs,
      })
    >;
typedef $$EmployeeRatesTableCreateCompanionBuilder =
    EmployeeRatesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      required String employeeId,
      required String rateType,
      required int amountMinor,
      required String currencyCode,
      required LocalDate effectiveFrom,
      Value<LocalDate?> effectiveTo,
      Value<int> rowid,
    });
typedef $$EmployeeRatesTableUpdateCompanionBuilder =
    EmployeeRatesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      Value<String> employeeId,
      Value<String> rateType,
      Value<int> amountMinor,
      Value<String> currencyCode,
      Value<LocalDate> effectiveFrom,
      Value<LocalDate?> effectiveTo,
      Value<int> rowid,
    });

final class $$EmployeeRatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $EmployeeRatesTable, EmployeeRateRow> {
  $$EmployeeRatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('employee_rates__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<String>('employee_id')!;

    final manager = $$EmployeesTableTableManager(
      $_db,
      $_db.employees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EmployeeRatesTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeeRatesTable> {
  $$EmployeeRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rateType => $composableBuilder(
    column: $table.rateType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String>
  get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String>
  get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableFilterComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmployeeRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeeRatesTable> {
  $$EmployeeRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rateType => $composableBuilder(
    column: $table.rateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableOrderingComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmployeeRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeeRatesTable> {
  $$EmployeeRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get rateType =>
      $composableBuilder(column: $table.rateType, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LocalDate, String> get effectiveFrom =>
      $composableBuilder(
        column: $table.effectiveFrom,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<LocalDate?, String> get effectiveTo =>
      $composableBuilder(
        column: $table.effectiveTo,
        builder: (column) => column,
      );

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableAnnotationComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmployeeRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployeeRatesTable,
          EmployeeRateRow,
          $$EmployeeRatesTableFilterComposer,
          $$EmployeeRatesTableOrderingComposer,
          $$EmployeeRatesTableAnnotationComposer,
          $$EmployeeRatesTableCreateCompanionBuilder,
          $$EmployeeRatesTableUpdateCompanionBuilder,
          (EmployeeRateRow, $$EmployeeRatesTableReferences),
          EmployeeRateRow,
          PrefetchHooks Function({bool employeeId})
        > {
  $$EmployeeRatesTableTableManager(_$AppDatabase db, $EmployeeRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeeRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeeRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeeRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> employeeId = const Value.absent(),
                Value<String> rateType = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<LocalDate> effectiveFrom = const Value.absent(),
                Value<LocalDate?> effectiveTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeeRatesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                employeeId: employeeId,
                rateType: rateType,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                effectiveFrom: effectiveFrom,
                effectiveTo: effectiveTo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String employeeId,
                required String rateType,
                required int amountMinor,
                required String currencyCode,
                required LocalDate effectiveFrom,
                Value<LocalDate?> effectiveTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeeRatesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                employeeId: employeeId,
                rateType: rateType,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                effectiveFrom: effectiveFrom,
                effectiveTo: effectiveTo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EmployeeRatesTable, EmployeeRateRow>(table),
                  $$EmployeeRatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (employeeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.employeeId,
                                referencedTable: $$EmployeeRatesTableReferences
                                    ._employeeIdTable(db),
                                referencedColumn: $$EmployeeRatesTableReferences
                                    ._employeeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EmployeeRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployeeRatesTable,
      EmployeeRateRow,
      $$EmployeeRatesTableFilterComposer,
      $$EmployeeRatesTableOrderingComposer,
      $$EmployeeRatesTableAnnotationComposer,
      $$EmployeeRatesTableCreateCompanionBuilder,
      $$EmployeeRatesTableUpdateCompanionBuilder,
      (EmployeeRateRow, $$EmployeeRatesTableReferences),
      EmployeeRateRow,
      PrefetchHooks Function({bool employeeId})
    >;
typedef $$CredentialsTableCreateCompanionBuilder =
    CredentialsCompanion Function({
      required String id,
      required String kind,
      Value<String?> adminUserId,
      Value<String?> employeeId,
      required String secretHash,
      Value<bool> isTemporary,
      Value<int> failedAttempts,
      Value<DateTime?> lockedUntil,
      required DateTime changedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CredentialsTableUpdateCompanionBuilder =
    CredentialsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String?> adminUserId,
      Value<String?> employeeId,
      Value<String> secretHash,
      Value<bool> isTemporary,
      Value<int> failedAttempts,
      Value<DateTime?> lockedUntil,
      Value<DateTime> changedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CredentialsTableReferences
    extends BaseReferences<_$AppDatabase, $CredentialsTable, CredentialRow> {
  $$CredentialsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AdminUsersTable _adminUserIdTable(_$AppDatabase db) =>
      db.adminUsers.createAlias('credentials__admin_user_id__admin_users__id');

  $$AdminUsersTableProcessedTableManager? get adminUserId {
    final $_column = $_itemColumn<String>('admin_user_id');
    if ($_column == null) return null;
    final manager = $$AdminUsersTableTableManager(
      $_db,
      $_db.adminUsers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_adminUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('credentials__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<String>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager(
      $_db,
      $_db.employees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CredentialsTableFilterComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secretHash => $composableBuilder(
    column: $table.secretHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTemporary => $composableBuilder(
    column: $table.isTemporary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AdminUsersTableFilterComposer get adminUserId {
    final $$AdminUsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adminUserId,
      referencedTable: $db.adminUsers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdminUsersTableFilterComposer(
            $db: $db,
            $table: $db.adminUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableFilterComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialsTableOrderingComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secretHash => $composableBuilder(
    column: $table.secretHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTemporary => $composableBuilder(
    column: $table.isTemporary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AdminUsersTableOrderingComposer get adminUserId {
    final $$AdminUsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adminUserId,
      referencedTable: $db.adminUsers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdminUsersTableOrderingComposer(
            $db: $db,
            $table: $db.adminUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableOrderingComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get secretHash => $composableBuilder(
    column: $table.secretHash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTemporary => $composableBuilder(
    column: $table.isTemporary,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AdminUsersTableAnnotationComposer get adminUserId {
    final $$AdminUsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adminUserId,
      referencedTable: $db.adminUsers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdminUsersTableAnnotationComposer(
            $db: $db,
            $table: $db.adminUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableAnnotationComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CredentialsTable,
          CredentialRow,
          $$CredentialsTableFilterComposer,
          $$CredentialsTableOrderingComposer,
          $$CredentialsTableAnnotationComposer,
          $$CredentialsTableCreateCompanionBuilder,
          $$CredentialsTableUpdateCompanionBuilder,
          (CredentialRow, $$CredentialsTableReferences),
          CredentialRow,
          PrefetchHooks Function({bool adminUserId, bool employeeId})
        > {
  $$CredentialsTableTableManager(_$AppDatabase db, $CredentialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CredentialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CredentialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CredentialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> adminUserId = const Value.absent(),
                Value<String?> employeeId = const Value.absent(),
                Value<String> secretHash = const Value.absent(),
                Value<bool> isTemporary = const Value.absent(),
                Value<int> failedAttempts = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CredentialsCompanion(
                id: id,
                kind: kind,
                adminUserId: adminUserId,
                employeeId: employeeId,
                secretHash: secretHash,
                isTemporary: isTemporary,
                failedAttempts: failedAttempts,
                lockedUntil: lockedUntil,
                changedAt: changedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<String?> adminUserId = const Value.absent(),
                Value<String?> employeeId = const Value.absent(),
                required String secretHash,
                Value<bool> isTemporary = const Value.absent(),
                Value<int> failedAttempts = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                required DateTime changedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CredentialsCompanion.insert(
                id: id,
                kind: kind,
                adminUserId: adminUserId,
                employeeId: employeeId,
                secretHash: secretHash,
                isTemporary: isTemporary,
                failedAttempts: failedAttempts,
                lockedUntil: lockedUntil,
                changedAt: changedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CredentialsTable, CredentialRow>(table),
                  $$CredentialsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({adminUserId = false, employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (adminUserId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.adminUserId,
                                referencedTable: $$CredentialsTableReferences
                                    ._adminUserIdTable(db),
                                referencedColumn: $$CredentialsTableReferences
                                    ._adminUserIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (employeeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.employeeId,
                                referencedTable: $$CredentialsTableReferences
                                    ._employeeIdTable(db),
                                referencedColumn: $$CredentialsTableReferences
                                    ._employeeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CredentialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CredentialsTable,
      CredentialRow,
      $$CredentialsTableFilterComposer,
      $$CredentialsTableOrderingComposer,
      $$CredentialsTableAnnotationComposer,
      $$CredentialsTableCreateCompanionBuilder,
      $$CredentialsTableUpdateCompanionBuilder,
      (CredentialRow, $$CredentialsTableReferences),
      CredentialRow,
      PrefetchHooks Function({bool adminUserId, bool employeeId})
    >;
typedef $$AuditLogTableCreateCompanionBuilder =
    AuditLogCompanion Function({
      required String id,
      required String companyId,
      required String actorType,
      Value<String?> actorId,
      required String action,
      required String entityType,
      Value<String?> entityId,
      required DateTime occurredAt,
      required String deviceId,
      Value<String?> metadata,
      Value<SyncState> syncState,
      Value<int> rowid,
    });
typedef $$AuditLogTableUpdateCompanionBuilder =
    AuditLogCompanion Function({
      Value<String> id,
      Value<String> companyId,
      Value<String> actorType,
      Value<String?> actorId,
      Value<String> action,
      Value<String> entityType,
      Value<String?> entityId,
      Value<DateTime> occurredAt,
      Value<String> deviceId,
      Value<String?> metadata,
      Value<SyncState> syncState,
      Value<int> rowid,
    });

final class $$AuditLogTableReferences
    extends BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow> {
  $$AuditLogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CompaniesTable _companyIdTable(_$AppDatabase db) =>
      db.companies.createAlias('audit_log__company_id__companies__id');

  $$CompaniesTableProcessedTableManager get companyId {
    final $_column = $_itemColumn<String>('company_id')!;

    final manager = $$CompaniesTableTableManager(
      $_db,
      $_db.companies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_companyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorType => $composableBuilder(
    column: $table.actorType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CompaniesTableFilterComposer get companyId {
    final $$CompaniesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableFilterComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorType => $composableBuilder(
    column: $table.actorType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompaniesTableOrderingComposer get companyId {
    final $$CompaniesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableOrderingComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actorType =>
      $composableBuilder(column: $table.actorType, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  $$CompaniesTableAnnotationComposer get companyId {
    final $$CompaniesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableAnnotationComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogTable,
          AuditLogRow,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (AuditLogRow, $$AuditLogTableReferences),
          AuditLogRow,
          PrefetchHooks Function({bool companyId})
        > {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> actorType = const Value.absent(),
                Value<String?> actorId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                companyId: companyId,
                actorType: actorType,
                actorId: actorId,
                action: action,
                entityType: entityType,
                entityId: entityId,
                occurredAt: occurredAt,
                deviceId: deviceId,
                metadata: metadata,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String actorType,
                Value<String?> actorId = const Value.absent(),
                required String action,
                required String entityType,
                Value<String?> entityId = const Value.absent(),
                required DateTime occurredAt,
                required String deviceId,
                Value<String?> metadata = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion.insert(
                id: id,
                companyId: companyId,
                actorType: actorType,
                actorId: actorId,
                action: action,
                entityType: entityType,
                entityId: entityId,
                occurredAt: occurredAt,
                deviceId: deviceId,
                metadata: metadata,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditLogTable, AuditLogRow>(table),
                  $$AuditLogTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({companyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (companyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.companyId,
                                referencedTable: $$AuditLogTableReferences
                                    ._companyIdTable(db),
                                referencedColumn: $$AuditLogTableReferences
                                    ._companyIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogTable,
      AuditLogRow,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (AuditLogRow, $$AuditLogTableReferences),
      AuditLogRow,
      PrefetchHooks Function({bool companyId})
    >;
typedef $$DeviceIdentityTableCreateCompanionBuilder =
    DeviceIdentityCompanion Function({
      required String id,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DeviceIdentityTableUpdateCompanionBuilder =
    DeviceIdentityCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DeviceIdentityTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceIdentityTable> {
  $$DeviceIdentityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceIdentityTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceIdentityTable> {
  $$DeviceIdentityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceIdentityTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceIdentityTable> {
  $$DeviceIdentityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DeviceIdentityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceIdentityTable,
          DeviceIdentityRow,
          $$DeviceIdentityTableFilterComposer,
          $$DeviceIdentityTableOrderingComposer,
          $$DeviceIdentityTableAnnotationComposer,
          $$DeviceIdentityTableCreateCompanionBuilder,
          $$DeviceIdentityTableUpdateCompanionBuilder,
          (
            DeviceIdentityRow,
            BaseReferences<
              _$AppDatabase,
              $DeviceIdentityTable,
              DeviceIdentityRow
            >,
          ),
          DeviceIdentityRow,
          PrefetchHooks Function()
        > {
  $$DeviceIdentityTableTableManager(
    _$AppDatabase db,
    $DeviceIdentityTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceIdentityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceIdentityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceIdentityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceIdentityCompanion(
                id: id,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DeviceIdentityCompanion.insert(
                id: id,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeviceIdentityTable, DeviceIdentityRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DeviceIdentityTable,
                    DeviceIdentityRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceIdentityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceIdentityTable,
      DeviceIdentityRow,
      $$DeviceIdentityTableFilterComposer,
      $$DeviceIdentityTableOrderingComposer,
      $$DeviceIdentityTableAnnotationComposer,
      $$DeviceIdentityTableCreateCompanionBuilder,
      $$DeviceIdentityTableUpdateCompanionBuilder,
      (
        DeviceIdentityRow,
        BaseReferences<_$AppDatabase, $DeviceIdentityTable, DeviceIdentityRow>,
      ),
      DeviceIdentityRow,
      PrefetchHooks Function()
    >;
typedef $$AttendanceEventsTableCreateCompanionBuilder =
    AttendanceEventsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      required String employeeId,
      required String eventType,
      required DateTime occurredAt,
      required DateTime recordedAt,
      required String source,
      required String deviceId,
      required String createdBy,
      Value<int> rowid,
    });
typedef $$AttendanceEventsTableUpdateCompanionBuilder =
    AttendanceEventsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      Value<String> employeeId,
      Value<String> eventType,
      Value<DateTime> occurredAt,
      Value<DateTime> recordedAt,
      Value<String> source,
      Value<String> deviceId,
      Value<String> createdBy,
      Value<int> rowid,
    });

final class $$AttendanceEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AttendanceEventsTable,
          AttendanceEventRow
        > {
  $$AttendanceEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('attendance_events__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<String>('employee_id')!;

    final manager = $$EmployeesTableTableManager(
      $_db,
      $_db.employees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttendanceEventsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceEventsTable> {
  $$AttendanceEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableFilterComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceEventsTable> {
  $$AttendanceEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableOrderingComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceEventsTable> {
  $$AttendanceEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableAnnotationComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceEventsTable,
          AttendanceEventRow,
          $$AttendanceEventsTableFilterComposer,
          $$AttendanceEventsTableOrderingComposer,
          $$AttendanceEventsTableAnnotationComposer,
          $$AttendanceEventsTableCreateCompanionBuilder,
          $$AttendanceEventsTableUpdateCompanionBuilder,
          (AttendanceEventRow, $$AttendanceEventsTableReferences),
          AttendanceEventRow,
          PrefetchHooks Function({bool employeeId})
        > {
  $$AttendanceEventsTableTableManager(
    _$AppDatabase db,
    $AttendanceEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> employeeId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceEventsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                employeeId: employeeId,
                eventType: eventType,
                occurredAt: occurredAt,
                recordedAt: recordedAt,
                source: source,
                deviceId: deviceId,
                createdBy: createdBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String employeeId,
                required String eventType,
                required DateTime occurredAt,
                required DateTime recordedAt,
                required String source,
                required String deviceId,
                required String createdBy,
                Value<int> rowid = const Value.absent(),
              }) => AttendanceEventsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                employeeId: employeeId,
                eventType: eventType,
                occurredAt: occurredAt,
                recordedAt: recordedAt,
                source: source,
                deviceId: deviceId,
                createdBy: createdBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttendanceEventsTable, AttendanceEventRow>(
                    table,
                  ),
                  $$AttendanceEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (employeeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.employeeId,
                                referencedTable:
                                    $$AttendanceEventsTableReferences
                                        ._employeeIdTable(db),
                                referencedColumn:
                                    $$AttendanceEventsTableReferences
                                        ._employeeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttendanceEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceEventsTable,
      AttendanceEventRow,
      $$AttendanceEventsTableFilterComposer,
      $$AttendanceEventsTableOrderingComposer,
      $$AttendanceEventsTableAnnotationComposer,
      $$AttendanceEventsTableCreateCompanionBuilder,
      $$AttendanceEventsTableUpdateCompanionBuilder,
      (AttendanceEventRow, $$AttendanceEventsTableReferences),
      AttendanceEventRow,
      PrefetchHooks Function({bool employeeId})
    >;
typedef $$AttendanceSettingsTableCreateCompanionBuilder =
    AttendanceSettingsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      required String companyId,
      required int duplicateWindowMinutes,
      required int staleOpenSessionMinutes,
      required int excessiveDurationMinutes,
      Value<int?> breakAfterMinutes,
      Value<int?> breakMinutes,
      Value<int> rowid,
    });
typedef $$AttendanceSettingsTableUpdateCompanionBuilder =
    AttendanceSettingsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      Value<String> companyId,
      Value<int> duplicateWindowMinutes,
      Value<int> staleOpenSessionMinutes,
      Value<int> excessiveDurationMinutes,
      Value<int?> breakAfterMinutes,
      Value<int?> breakMinutes,
      Value<int> rowid,
    });

final class $$AttendanceSettingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AttendanceSettingsTable,
          AttendanceSettingsRow
        > {
  $$AttendanceSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompaniesTable _companyIdTable(_$AppDatabase db) => db.companies
      .createAlias('attendance_settings__company_id__companies__id');

  $$CompaniesTableProcessedTableManager get companyId {
    final $_column = $_itemColumn<String>('company_id')!;

    final manager = $$CompaniesTableTableManager(
      $_db,
      $_db.companies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_companyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttendanceSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceSettingsTable> {
  $$AttendanceSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duplicateWindowMinutes => $composableBuilder(
    column: $table.duplicateWindowMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get staleOpenSessionMinutes => $composableBuilder(
    column: $table.staleOpenSessionMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get excessiveDurationMinutes => $composableBuilder(
    column: $table.excessiveDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakAfterMinutes => $composableBuilder(
    column: $table.breakAfterMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$CompaniesTableFilterComposer get companyId {
    final $$CompaniesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableFilterComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceSettingsTable> {
  $$AttendanceSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duplicateWindowMinutes => $composableBuilder(
    column: $table.duplicateWindowMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get staleOpenSessionMinutes => $composableBuilder(
    column: $table.staleOpenSessionMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get excessiveDurationMinutes => $composableBuilder(
    column: $table.excessiveDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakAfterMinutes => $composableBuilder(
    column: $table.breakAfterMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompaniesTableOrderingComposer get companyId {
    final $$CompaniesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableOrderingComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceSettingsTable> {
  $$AttendanceSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get duplicateWindowMinutes => $composableBuilder(
    column: $table.duplicateWindowMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get staleOpenSessionMinutes => $composableBuilder(
    column: $table.staleOpenSessionMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get excessiveDurationMinutes => $composableBuilder(
    column: $table.excessiveDurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breakAfterMinutes => $composableBuilder(
    column: $table.breakAfterMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => column,
  );

  $$CompaniesTableAnnotationComposer get companyId {
    final $$CompaniesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.companyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableAnnotationComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceSettingsTable,
          AttendanceSettingsRow,
          $$AttendanceSettingsTableFilterComposer,
          $$AttendanceSettingsTableOrderingComposer,
          $$AttendanceSettingsTableAnnotationComposer,
          $$AttendanceSettingsTableCreateCompanionBuilder,
          $$AttendanceSettingsTableUpdateCompanionBuilder,
          (AttendanceSettingsRow, $$AttendanceSettingsTableReferences),
          AttendanceSettingsRow,
          PrefetchHooks Function({bool companyId})
        > {
  $$AttendanceSettingsTableTableManager(
    _$AppDatabase db,
    $AttendanceSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<int> duplicateWindowMinutes = const Value.absent(),
                Value<int> staleOpenSessionMinutes = const Value.absent(),
                Value<int> excessiveDurationMinutes = const Value.absent(),
                Value<int?> breakAfterMinutes = const Value.absent(),
                Value<int?> breakMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceSettingsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                companyId: companyId,
                duplicateWindowMinutes: duplicateWindowMinutes,
                staleOpenSessionMinutes: staleOpenSessionMinutes,
                excessiveDurationMinutes: excessiveDurationMinutes,
                breakAfterMinutes: breakAfterMinutes,
                breakMinutes: breakMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String companyId,
                required int duplicateWindowMinutes,
                required int staleOpenSessionMinutes,
                required int excessiveDurationMinutes,
                Value<int?> breakAfterMinutes = const Value.absent(),
                Value<int?> breakMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceSettingsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                companyId: companyId,
                duplicateWindowMinutes: duplicateWindowMinutes,
                staleOpenSessionMinutes: staleOpenSessionMinutes,
                excessiveDurationMinutes: excessiveDurationMinutes,
                breakAfterMinutes: breakAfterMinutes,
                breakMinutes: breakMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttendanceSettingsTable, AttendanceSettingsRow>(
                    table,
                  ),
                  $$AttendanceSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({companyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (companyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.companyId,
                                referencedTable:
                                    $$AttendanceSettingsTableReferences
                                        ._companyIdTable(db),
                                referencedColumn:
                                    $$AttendanceSettingsTableReferences
                                        ._companyIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttendanceSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceSettingsTable,
      AttendanceSettingsRow,
      $$AttendanceSettingsTableFilterComposer,
      $$AttendanceSettingsTableOrderingComposer,
      $$AttendanceSettingsTableAnnotationComposer,
      $$AttendanceSettingsTableCreateCompanionBuilder,
      $$AttendanceSettingsTableUpdateCompanionBuilder,
      (AttendanceSettingsRow, $$AttendanceSettingsTableReferences),
      AttendanceSettingsRow,
      PrefetchHooks Function({bool companyId})
    >;
typedef $$AttendanceCorrectionsTableCreateCompanionBuilder =
    AttendanceCorrectionsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      required String employeeId,
      required String kind,
      required String eventType,
      Value<String?> originalEventId,
      Value<String?> replacementEventId,
      Value<DateTime?> previousOccurredAt,
      Value<DateTime?> newOccurredAt,
      required String reason,
      required String correctedBy,
      required DateTime correctedAt,
      Value<int> rowid,
    });
typedef $$AttendanceCorrectionsTableUpdateCompanionBuilder =
    AttendanceCorrectionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<SyncState> syncState,
      Value<DateTime?> deletedAt,
      Value<String> employeeId,
      Value<String> kind,
      Value<String> eventType,
      Value<String?> originalEventId,
      Value<String?> replacementEventId,
      Value<DateTime?> previousOccurredAt,
      Value<DateTime?> newOccurredAt,
      Value<String> reason,
      Value<String> correctedBy,
      Value<DateTime> correctedAt,
      Value<int> rowid,
    });

final class $$AttendanceCorrectionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AttendanceCorrectionsTable,
          AttendanceCorrectionRow
        > {
  $$AttendanceCorrectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) => db.employees
      .createAlias('attendance_corrections__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<String>('employee_id')!;

    final manager = $$EmployeesTableTableManager(
      $_db,
      $_db.employees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AttendanceEventsTable _originalEventIdTable(_$AppDatabase db) =>
      db.attendanceEvents.createAlias(
        'attendance_corrections__original_event_id__attendance_events__id',
      );

  $$AttendanceEventsTableProcessedTableManager? get originalEventId {
    final $_column = $_itemColumn<String>('original_event_id');
    if ($_column == null) return null;
    final manager = $$AttendanceEventsTableTableManager(
      $_db,
      $_db.attendanceEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originalEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AttendanceEventsTable _replacementEventIdTable(_$AppDatabase db) =>
      db.attendanceEvents.createAlias(
        'attendance_corrections__replacement_event_id__attendance_events__id',
      );

  $$AttendanceEventsTableProcessedTableManager? get replacementEventId {
    final $_column = $_itemColumn<String>('replacement_event_id');
    if ($_column == null) return null;
    final manager = $$AttendanceEventsTableTableManager(
      $_db,
      $_db.attendanceEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_replacementEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AdminUsersTable _correctedByTable(_$AppDatabase db) => db.adminUsers
      .createAlias('attendance_corrections__corrected_by__admin_users__id');

  $$AdminUsersTableProcessedTableManager get correctedBy {
    final $_column = $_itemColumn<String>('corrected_by')!;

    final manager = $$AdminUsersTableTableManager(
      $_db,
      $_db.adminUsers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_correctedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttendanceCorrectionsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceCorrectionsTable> {
  $$AttendanceCorrectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get previousOccurredAt => $composableBuilder(
    column: $table.previousOccurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get newOccurredAt => $composableBuilder(
    column: $table.newOccurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get correctedAt => $composableBuilder(
    column: $table.correctedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableFilterComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AttendanceEventsTableFilterComposer get originalEventId {
    final $$AttendanceEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originalEventId,
      referencedTable: $db.attendanceEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceEventsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AttendanceEventsTableFilterComposer get replacementEventId {
    final $$AttendanceEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.replacementEventId,
      referencedTable: $db.attendanceEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceEventsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AdminUsersTableFilterComposer get correctedBy {
    final $$AdminUsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.correctedBy,
      referencedTable: $db.adminUsers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdminUsersTableFilterComposer(
            $db: $db,
            $table: $db.adminUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceCorrectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceCorrectionsTable> {
  $$AttendanceCorrectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get previousOccurredAt => $composableBuilder(
    column: $table.previousOccurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get newOccurredAt => $composableBuilder(
    column: $table.newOccurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get correctedAt => $composableBuilder(
    column: $table.correctedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableOrderingComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AttendanceEventsTableOrderingComposer get originalEventId {
    final $$AttendanceEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originalEventId,
      referencedTable: $db.attendanceEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceEventsTableOrderingComposer(
            $db: $db,
            $table: $db.attendanceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AttendanceEventsTableOrderingComposer get replacementEventId {
    final $$AttendanceEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.replacementEventId,
      referencedTable: $db.attendanceEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceEventsTableOrderingComposer(
            $db: $db,
            $table: $db.attendanceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AdminUsersTableOrderingComposer get correctedBy {
    final $$AdminUsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.correctedBy,
      referencedTable: $db.adminUsers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdminUsersTableOrderingComposer(
            $db: $db,
            $table: $db.adminUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceCorrectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceCorrectionsTable> {
  $$AttendanceCorrectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get previousOccurredAt => $composableBuilder(
    column: $table.previousOccurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get newOccurredAt => $composableBuilder(
    column: $table.newOccurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get correctedAt => $composableBuilder(
    column: $table.correctedAt,
    builder: (column) => column,
  );

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableAnnotationComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AttendanceEventsTableAnnotationComposer get originalEventId {
    final $$AttendanceEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originalEventId,
      referencedTable: $db.attendanceEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.attendanceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AttendanceEventsTableAnnotationComposer get replacementEventId {
    final $$AttendanceEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.replacementEventId,
      referencedTable: $db.attendanceEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.attendanceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AdminUsersTableAnnotationComposer get correctedBy {
    final $$AdminUsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.correctedBy,
      referencedTable: $db.adminUsers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdminUsersTableAnnotationComposer(
            $db: $db,
            $table: $db.adminUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceCorrectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceCorrectionsTable,
          AttendanceCorrectionRow,
          $$AttendanceCorrectionsTableFilterComposer,
          $$AttendanceCorrectionsTableOrderingComposer,
          $$AttendanceCorrectionsTableAnnotationComposer,
          $$AttendanceCorrectionsTableCreateCompanionBuilder,
          $$AttendanceCorrectionsTableUpdateCompanionBuilder,
          (AttendanceCorrectionRow, $$AttendanceCorrectionsTableReferences),
          AttendanceCorrectionRow,
          PrefetchHooks Function({
            bool employeeId,
            bool originalEventId,
            bool replacementEventId,
            bool correctedBy,
          })
        > {
  $$AttendanceCorrectionsTableTableManager(
    _$AppDatabase db,
    $AttendanceCorrectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceCorrectionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AttendanceCorrectionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceCorrectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> employeeId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> originalEventId = const Value.absent(),
                Value<String?> replacementEventId = const Value.absent(),
                Value<DateTime?> previousOccurredAt = const Value.absent(),
                Value<DateTime?> newOccurredAt = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> correctedBy = const Value.absent(),
                Value<DateTime> correctedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceCorrectionsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                employeeId: employeeId,
                kind: kind,
                eventType: eventType,
                originalEventId: originalEventId,
                replacementEventId: replacementEventId,
                previousOccurredAt: previousOccurredAt,
                newOccurredAt: newOccurredAt,
                reason: reason,
                correctedBy: correctedBy,
                correctedAt: correctedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String employeeId,
                required String kind,
                required String eventType,
                Value<String?> originalEventId = const Value.absent(),
                Value<String?> replacementEventId = const Value.absent(),
                Value<DateTime?> previousOccurredAt = const Value.absent(),
                Value<DateTime?> newOccurredAt = const Value.absent(),
                required String reason,
                required String correctedBy,
                required DateTime correctedAt,
                Value<int> rowid = const Value.absent(),
              }) => AttendanceCorrectionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                syncState: syncState,
                deletedAt: deletedAt,
                employeeId: employeeId,
                kind: kind,
                eventType: eventType,
                originalEventId: originalEventId,
                replacementEventId: replacementEventId,
                previousOccurredAt: previousOccurredAt,
                newOccurredAt: newOccurredAt,
                reason: reason,
                correctedBy: correctedBy,
                correctedAt: correctedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AttendanceCorrectionsTable,
                    AttendanceCorrectionRow
                  >(table),
                  $$AttendanceCorrectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                employeeId = false,
                originalEventId = false,
                replacementEventId = false,
                correctedBy = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (employeeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.employeeId,
                                    referencedTable:
                                        $$AttendanceCorrectionsTableReferences
                                            ._employeeIdTable(db),
                                    referencedColumn:
                                        $$AttendanceCorrectionsTableReferences
                                            ._employeeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (originalEventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.originalEventId,
                                    referencedTable:
                                        $$AttendanceCorrectionsTableReferences
                                            ._originalEventIdTable(db),
                                    referencedColumn:
                                        $$AttendanceCorrectionsTableReferences
                                            ._originalEventIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (replacementEventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.replacementEventId,
                                    referencedTable:
                                        $$AttendanceCorrectionsTableReferences
                                            ._replacementEventIdTable(db),
                                    referencedColumn:
                                        $$AttendanceCorrectionsTableReferences
                                            ._replacementEventIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (correctedBy) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.correctedBy,
                                    referencedTable:
                                        $$AttendanceCorrectionsTableReferences
                                            ._correctedByTable(db),
                                    referencedColumn:
                                        $$AttendanceCorrectionsTableReferences
                                            ._correctedByTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$AttendanceCorrectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceCorrectionsTable,
      AttendanceCorrectionRow,
      $$AttendanceCorrectionsTableFilterComposer,
      $$AttendanceCorrectionsTableOrderingComposer,
      $$AttendanceCorrectionsTableAnnotationComposer,
      $$AttendanceCorrectionsTableCreateCompanionBuilder,
      $$AttendanceCorrectionsTableUpdateCompanionBuilder,
      (AttendanceCorrectionRow, $$AttendanceCorrectionsTableReferences),
      AttendanceCorrectionRow,
      PrefetchHooks Function({
        bool employeeId,
        bool originalEventId,
        bool replacementEventId,
        bool correctedBy,
      })
    >;
typedef $$DeviceSettingsTableCreateCompanionBuilder =
    DeviceSettingsCompanion Function({
      required String id,
      Value<String?> kioskCompanyId,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DeviceSettingsTableUpdateCompanionBuilder =
    DeviceSettingsCompanion Function({
      Value<String> id,
      Value<String?> kioskCompanyId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DeviceSettingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $DeviceSettingsTable, DeviceSettingsRow> {
  $$DeviceSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompaniesTable _kioskCompanyIdTable(_$AppDatabase db) => db.companies
      .createAlias('device_settings__kiosk_company_id__companies__id');

  $$CompaniesTableProcessedTableManager? get kioskCompanyId {
    final $_column = $_itemColumn<String>('kiosk_company_id');
    if ($_column == null) return null;
    final manager = $$CompaniesTableTableManager(
      $_db,
      $_db.companies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_kioskCompanyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DeviceSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceSettingsTable> {
  $$DeviceSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CompaniesTableFilterComposer get kioskCompanyId {
    final $$CompaniesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.kioskCompanyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableFilterComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeviceSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceSettingsTable> {
  $$DeviceSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompaniesTableOrderingComposer get kioskCompanyId {
    final $$CompaniesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.kioskCompanyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableOrderingComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeviceSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceSettingsTable> {
  $$DeviceSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CompaniesTableAnnotationComposer get kioskCompanyId {
    final $$CompaniesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.kioskCompanyId,
      referencedTable: $db.companies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompaniesTableAnnotationComposer(
            $db: $db,
            $table: $db.companies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeviceSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceSettingsTable,
          DeviceSettingsRow,
          $$DeviceSettingsTableFilterComposer,
          $$DeviceSettingsTableOrderingComposer,
          $$DeviceSettingsTableAnnotationComposer,
          $$DeviceSettingsTableCreateCompanionBuilder,
          $$DeviceSettingsTableUpdateCompanionBuilder,
          (DeviceSettingsRow, $$DeviceSettingsTableReferences),
          DeviceSettingsRow,
          PrefetchHooks Function({bool kioskCompanyId})
        > {
  $$DeviceSettingsTableTableManager(
    _$AppDatabase db,
    $DeviceSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> kioskCompanyId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceSettingsCompanion(
                id: id,
                kioskCompanyId: kioskCompanyId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> kioskCompanyId = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DeviceSettingsCompanion.insert(
                id: id,
                kioskCompanyId: kioskCompanyId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeviceSettingsTable, DeviceSettingsRow>(table),
                  $$DeviceSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({kioskCompanyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (kioskCompanyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.kioskCompanyId,
                                referencedTable: $$DeviceSettingsTableReferences
                                    ._kioskCompanyIdTable(db),
                                referencedColumn:
                                    $$DeviceSettingsTableReferences
                                        ._kioskCompanyIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DeviceSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceSettingsTable,
      DeviceSettingsRow,
      $$DeviceSettingsTableFilterComposer,
      $$DeviceSettingsTableOrderingComposer,
      $$DeviceSettingsTableAnnotationComposer,
      $$DeviceSettingsTableCreateCompanionBuilder,
      $$DeviceSettingsTableUpdateCompanionBuilder,
      (DeviceSettingsRow, $$DeviceSettingsTableReferences),
      DeviceSettingsRow,
      PrefetchHooks Function({bool kioskCompanyId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CompaniesTableTableManager get companies =>
      $$CompaniesTableTableManager(_db, _db.companies);
  $$AdminUsersTableTableManager get adminUsers =>
      $$AdminUsersTableTableManager(_db, _db.adminUsers);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db, _db.employees);
  $$EmployeeRatesTableTableManager get employeeRates =>
      $$EmployeeRatesTableTableManager(_db, _db.employeeRates);
  $$CredentialsTableTableManager get credentials =>
      $$CredentialsTableTableManager(_db, _db.credentials);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$DeviceIdentityTableTableManager get deviceIdentity =>
      $$DeviceIdentityTableTableManager(_db, _db.deviceIdentity);
  $$AttendanceEventsTableTableManager get attendanceEvents =>
      $$AttendanceEventsTableTableManager(_db, _db.attendanceEvents);
  $$AttendanceSettingsTableTableManager get attendanceSettings =>
      $$AttendanceSettingsTableTableManager(_db, _db.attendanceSettings);
  $$AttendanceCorrectionsTableTableManager get attendanceCorrections =>
      $$AttendanceCorrectionsTableTableManager(_db, _db.attendanceCorrections);
  $$DeviceSettingsTableTableManager get deviceSettings =>
      $$DeviceSettingsTableTableManager(_db, _db.deviceSettings);
}
