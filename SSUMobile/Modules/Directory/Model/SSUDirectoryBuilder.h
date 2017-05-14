//
//  SSUDirectoryBuilder.h
//  SSUMobile
//
//  Created by Andrew Huss on 1/22/13.
//  Copyright (c) 2013 Sonoma State University Department of Computer Science. All rights reserved.
//

@import Foundation;
#import "SSUMoonlightBuilder.h"
#import "SSUDirectoryConstants.h"
#import "SSUPerson.h"
#import "SSUDepartment.h"
#import "SSUBuilding.h"
#import "SSUSchool.h"

@interface SSUDirectoryBuilder : SSUMoonlightBuilder

- (void) buildPeople:(NSArray *)people;
- (void) buildDepartments:(NSArray *)departments;
- (void) buildBuildings:(NSArray *)buildings;
- (void) buildSchools:(NSArray *)schools;

- (SSUPerson *) personWithID:(NSString*)personID;
- (SSUDepartment *) departmentWithID:(NSString*)departmentID;
- (SSUBuilding *) buildingWithID:(NSString*)buildingID;
- (SSUSchool *) schoolWithID:(NSString *)schoolID;

- (SSUBuilding *) buildingWithName:(NSString*)buildingName;
- (SSUPerson *) personWithFirstName:(NSString*)personFirstName andLastName:(NSString*)personLastName;

+ (SSUPerson *) personWithID:(NSString*)personID inContext:(NSManagedObjectContext*)context;
+ (SSUDepartment *) departmentWithID:(NSString*)departmentID inContext:(NSManagedObjectContext*)context;
+ (SSUBuilding *) buildingWithID:(NSString*)buildingID inContext:(NSManagedObjectContext*)context;
+ (SSUSchool *) schoolWithID:(NSString *)schoolID inContext:(NSManagedObjectContext *)context;

+ (SSUPerson *) personWithFirstName:(NSString*)personFirstName andLastName:(NSString*)personLastName inContext:(NSManagedObjectContext*)context;
+ (SSUBuilding *) buildingWithName:(NSString*)buildingName inContext:(NSManagedObjectContext*)context;

@end
