//
//  SSUDirectoryBuilder.m
//  SSUMobile
//
//  Created by Andrew Huss on 1/22/13.
//  Copyright (c) 2013 Sonoma State University Department of Computer Science. All rights reserved.
//

#import "SSUDirectoryBuilder.h"
#import "SSUDirectoryConstants.h"
#import "SSUDirectoryModels.h"
#import "SSULogging.h"

NSString * const SSUDirectoryPersonKeyEmail = @"email";
NSString * const SSUDirectoryPersonKeyDisplayName = @"display_name";
NSString * const SSUDirectoryPersonKeyFirstName = @"first_name";
NSString * const SSUDirectoryPersonKeyLastName = @"last_name";
NSString * const SSUDirectoryPersonKeyPhone = @"phone";
NSString * const SSUDirectoryPersonKeySite = @"site";
NSString * const SSUDirectoryPersonKeyTitle = @"title";
NSString * const SSUDirectoryPersonKeyOffice = @"office";
NSString * const SSUDirectoryPersonKeyBuilding = @"building";
NSString * const SSUDirectoryPersonKeyDepartment = @"department";

NSString * const SSUDirectoryDepartmentKeyName = @"name";
NSString * const SSUDirectoryDepartmentKeyDisplayName = @"display_name";
NSString * const SSUDirectoryDepartmentKeyPhone = @"phone";
NSString * const SSUDirectoryDepartmentKeyEmail = @"email";
NSString * const SSUDirectoryDepartmentKeySite = @"site";
NSString * const SSUDirectoryDepartmentKeyChairID = @"chair";
NSString * const SSUDirectoryDepartmentKeyACID = @"ac";
NSString * const SSUDirectoryDepartmentKeyBuildingID = @"building";
NSString * const SSUDirectoryDepartmentKeyRoomID = @"office";
NSString * const SSUDirectoryDepartmentKeySchoolID = @"school";

NSString * const SSUDirectoryBuildingKeyName = @"name";

NSString * const SSUDirectorySchoolKeyName = @"name";
NSString * const SSUDirectorySchoolKeyDeanID = @"dean";
NSString * const SSUDirectorySchoolKeyAdminID = @"admin";
NSString * const SSUDirectorySchoolKeyAssistantID = @"assistant";
NSString * const SSUDirectorySchoolKeyBuildingID = @"building";

@implementation SSUDirectoryBuilder






- (SSUPerson *) personWithFirstName:(NSString *)personFirstName andLastName:(NSString *)personLastName {
    return [[self class] personWithFirstName:personFirstName andLastName:personLastName inContext:self.context];
}

+ (SSUPerson *) personWithFirstName:(NSString *)personFirstName andLastName:(NSString *)personLastName inContext:(NSManagedObjectContext *)context {
    //    if (personID.integerValue == 0)
    //        return nil;
    if ([personFirstName  isEqual: @""] && [personLastName  isEqual: @""]){
        return nil;
    }
    NSPredicate* fnPredicate = [NSPredicate predicateWithFormat:@"%K = %@", SSUDirectoryPersonKeyFirstName, personFirstName];
    NSPredicate* lnPredicate = [NSPredicate predicateWithFormat:@"%K = %@", SSUDirectoryPersonKeyLastName, personLastName];
    NSCompoundPredicate* predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[fnPredicate, lnPredicate]];
    
    BOOL created = NO;
    SSUPerson* person = (SSUPerson*)[self objectWithEntityName:SSUDirectoryEntityPerson predicate:predicate context: context entityWasCreated:&created];
    // SSUPerson * person = (SSUPerson*)[self objectWithEntityName:SSUDirectoryEntityPerson ID:personID context:context entityWasCreated:&created];
    if (created) {
        person.id = @"";
        person.sectionName = SSUDirectoryCategoryPeople;
        person.firstName = personFirstName;
        person.lastName = personLastName;
        person.displayName = [NSString stringWithFormat:@"%@ %@", personFirstName, personLastName];
    }
    
    return person;
}

- (SSUBuilding*) buildingWithName:(NSString *)buildingName{
    return [[self class] buildingWithName:buildingName inContext:self.context];
}

+ (SSUBuilding*) buildingWithName:(NSString *)buildingName inContext:(NSManagedObjectContext *)context{
    if ([buildingName isEqual:@""])
        return nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K = %@", SSUDirectoryBuildingKeyName, buildingName];
    BOOL created = NO;
    SSUBuilding* building = (SSUBuilding*)[self objectWithEntityName:SSUDirectoryEntityBuilding predicate:predicate context:context entityWasCreated:&created];
    if (created) {
        building.id = @"";
        building.sectionName = SSUDirectoryCategoryBuildings;
        building.name = buildingName;
        building.displayName = buildingName;
    }
    
    return building;
}





- (SSUPerson *) personWithID:(NSString *)personID {
    return [[self class] personWithID:personID inContext:self.context];
}

+ (SSUPerson *) personWithID:(NSString *)personID inContext:(NSManagedObjectContext *)context {
    if (personID.integerValue == 0)
        return nil;
    BOOL created = NO;
    SSUPerson * person = (SSUPerson*)[self objectWithEntityName:SSUDirectoryEntityPerson ID:personID context:context entityWasCreated:&created];
    if (created) {
        person.id = personID;
        person.sectionName = SSUDirectoryCategoryPeople;
        person.firstName = @"";
        person.lastName = @"";
        person.displayName = @"";
    }

    return person;
}

- (SSUDepartment *) departmentWithID:(NSString *)departmentID {
    return [[self class] departmentWithID:departmentID inContext:self.context];
}

+ (SSUDepartment *) departmentWithID:(NSString *)departmentID inContext:(NSManagedObjectContext *)context {
    if (departmentID.integerValue == 0)
        return nil;
    BOOL created = NO;
    SSUDepartment* department = (SSUDepartment *)[self objectWithEntityName:SSUDirectoryEntityDepartment ID:departmentID context:context entityWasCreated:&created];
    if (created) {
        department.id = departmentID;
        department.sectionName = SSUDirectoryCategoryDepartments;
        department.name = @"Unknown";
        department.displayName = @"Unknown";
    }

    return department;
}

- (SSUBuilding *) buildingWithID:(NSString *)buildingID {
    return [[self class] buildingWithID:buildingID inContext:self.context];
}

+ (SSUBuilding *) buildingWithID:(NSString*)buildingID inContext:(NSManagedObjectContext *)context {
    if (buildingID.integerValue == 0)
        return nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K = %@", SSUMoonlightManagerKeyID, buildingID];
    BOOL created = NO;
    SSUBuilding* building = (SSUBuilding*)[self objectWithEntityName:SSUDirectoryEntityBuilding predicate:predicate context:context entityWasCreated:&created];
    if (created) {
        building.id = [NSString stringWithFormat:@"%@",buildingID];
        building.sectionName = SSUDirectoryCategoryBuildings;
        building.name = @"Unknown";
        building.displayName = @"Unknown";
    }

    return building;
}

- (SSUSchool *) schoolWithID:(NSString *)schoolID {
    return [[self class] schoolWithID:schoolID inContext:self.context];
}

+ (SSUSchool *) schoolWithID:(NSString *)schoolID inContext:(NSManagedObjectContext *)context {
    if (schoolID == nil || schoolID.integerValue <= 0) {
        return nil;
    }
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"%K = %@", SSUMoonlightManagerKeyID, schoolID];
    BOOL created = NO;
    SSUSchool * school = (SSUSchool *)[self objectWithEntityName:SSUDirectoryEntitySchool predicate:predicate context:context entityWasCreated:&created];
    if (created) {
        school.id = schoolID;
        school.sectionName = SSUDirectoryCategorySchools;
    }

    return school;
}

- (void) updatePersonProperties {
    NSArray * allPeople = [self allObjectsWithEntityName:SSUDirectoryEntityPerson];
    [allPeople makeObjectsPerformSelector:@selector(updateNameOrder)];
}

- (void) updateDepartmentProperties {
    NSArray * allDepartments = [self allObjectsWithEntityName:SSUDirectoryEntityDepartment];
    [allDepartments makeObjectsPerformSelector:@selector(updateSectionName)];
}

//MARK: Build

- (void) buildPeople:(NSArray*)people {
    SSULogDebug(@"Started People: %lu", (unsigned long)people.count);
    NSDate* start = [NSDate date];
    
    for (NSDictionary* original in people) {
        NSDictionary * personData = [self cleanJSON:original];
        SSUMoonlightDataMode mode = [self modeFromJSONData:personData];
        
        NSString* personID = SSUMoonlightBuilderStringify(personData[SSUMoonlightManagerKeyID]);
        SSUPerson* person = [self personWithID:personID];
        if (person == nil)
            continue;
        if (mode == SSUMoonlightDataModeDeleted) {
            [self.context deleteObject:person];
            continue;
        }
        
        person.firstName = [personData[SSUDirectoryPersonKeyFirstName] stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        person.lastName = [personData[SSUDirectoryPersonKeyLastName] stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        person.displayName = personData[SSUDirectoryPersonKeyDisplayName];
        [person updateNameOrder];
        
        person.email = personData[SSUDirectoryPersonKeyEmail];
        person.phone = personData[SSUDirectoryPersonKeyPhone];
        person.site = personData[SSUDirectoryPersonKeySite];
        person.title = personData[SSUDirectoryPersonKeyTitle];
        person.office = personData[SSUDirectoryPersonKeyOffice];
        
        NSString* buildingID = SSUMoonlightBuilderStringify(personData[SSUDirectoryPersonKeyBuilding]);
        person.building = [self buildingWithID:buildingID];
        
        NSString* departmentID = SSUMoonlightBuilderStringify(personData[SSUDirectoryPersonKeyDepartment]);
        person.department = [self departmentWithID:departmentID];
    }
    
    [self updatePersonProperties];
    [self saveContext];
    
    SSULogDebug(@"Finished People: %f", [[NSDate date] timeIntervalSinceDate:start]);
}

- (void) buildBuildings:(NSArray*)buildings {
    SSULogDebug(@"Started Buildings: %lu", (unsigned long)buildings.count);
    NSDate* start = [NSDate date];
    for (NSDictionary* original in buildings) {
        NSDictionary* buildingData = [self cleanJSON:original];
        SSUBuilding* building = [SSUDirectoryBuilder buildingWithID:buildingData[SSUMoonlightManagerKeyID] inContext:self.context];
        
        if (building == nil)
            continue;
        SSUMoonlightDataMode mode = [self modeFromJSONData:buildingData];
        if (mode == SSUMoonlightDataModeDeleted) {
            [self.context deleteObject:building];
            continue;
        }
        building.name = buildingData[SSUDirectoryBuildingKeyName];
        building.displayName = building.name;
        building.term = building.name;
    }
    [self saveContext];
    SSULogDebug(@"Finished Buildings: %f", [[NSDate date] timeIntervalSinceDate:start]);
}

- (void) buildDepartments:(NSArray*)departments {
    SSULogDebug(@"Started Departments: %lu", (unsigned long)departments.count);
    NSDate* start = [NSDate date];

    for (NSDictionary* original in departments) {
        NSDictionary * departmentData = [self cleanJSON:original];
        SSUDepartment* department = [SSUDirectoryBuilder departmentWithID:departmentData[SSUMoonlightManagerKeyID] inContext:self.context];
        if (department == nil)
            continue;
        SSUMoonlightDataMode mode = [self modeFromJSONData:departmentData];
        if (mode == SSUMoonlightDataModeDeleted) {
            [self.context deleteObject:department];
            continue;
        }
        
        department.name = departmentData[SSUDirectoryDepartmentKeyName];
        NSString * displayName = departmentData[SSUDirectoryDepartmentKeyDisplayName];
        department.displayName = (!SSUIsEmptyString(displayName)) ? displayName : department.name;

        department.term = department.displayName;
        
        department.email = departmentData[SSUDirectoryDepartmentKeyEmail];
        department.phone = departmentData[SSUDirectoryDepartmentKeyPhone];
        department.site = departmentData[SSUDirectoryDepartmentKeySite];
        department.office = departmentData[SSUDirectoryDepartmentKeyRoomID];
        
        NSString * buildingID = SSUMoonlightBuilderStringify(departmentData[SSUDirectoryDepartmentKeyBuildingID]);
        department.building = [self buildingWithID:buildingID];
        
        NSString* chairID = SSUMoonlightBuilderStringify(departmentData[SSUDirectoryDepartmentKeyChairID]);
        department.chair = [self personWithID:chairID];
        
        NSString* acID = SSUMoonlightBuilderStringify(departmentData[SSUDirectoryDepartmentKeyACID]);
        department.ac = [self personWithID:acID];
        
        NSString * schoolID = SSUMoonlightBuilderStringify(departmentData[SSUDirectoryDepartmentKeySchoolID]);
        department.school = [self schoolWithID:schoolID];
    }
    
    [self updateDepartmentProperties];
    [self saveContext];
    SSULogDebug(@"Finished Department: %f", [[NSDate date] timeIntervalSinceDate:start]);
}

- (void) buildSchools:(NSArray *)schools {
    SSULogDebug(@"Started Schools: %lu", (unsigned long)schools.count);
    NSDate * start = [NSDate date];
    
    for (NSDictionary * school in schools) {
        NSDictionary * data = [self cleanJSON:school];
        NSString * schoolID = SSUMoonlightBuilderStringify(data[SSUMoonlightManagerKeyID]);
        SSUSchool * school = [self schoolWithID:schoolID];
        if (school == nil)
            continue;
        SSUMoonlightDataMode mode = [self modeFromJSONData:data];
        if (mode == SSUMoonlightDataModeDeleted) {
            [self.context deleteObject:school];
            continue;
        }
        
        school.name = data[SSUDirectorySchoolKeyName];
        school.term = school.name;
        school.displayName = school.name;
        
        NSString * deanID = SSUMoonlightBuilderStringify(data[SSUDirectorySchoolKeyDeanID]);
        school.dean = [self personWithID:deanID];
        
        NSString * adminID = SSUMoonlightBuilderStringify(data[SSUDirectorySchoolKeyAdminID]);
        school.admin = [self personWithID:adminID];
        
        NSString * assistantID = SSUMoonlightBuilderStringify(data[SSUDirectorySchoolKeyAssistantID]);
        school.assistant = [self personWithID:assistantID];
        
        NSString * buildingID = SSUMoonlightBuilderStringify(data[SSUDirectorySchoolKeyBuildingID]);
        school.building = [self buildingWithID:buildingID];

    }
    [self saveContext];
    SSULogDebug(@"Finished Schools: %fs", [[NSDate date] timeIntervalSinceDate:start]);
}

@end
