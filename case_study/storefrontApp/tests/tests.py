import httpx
import json


def announceTest(name: str):
    print(f'Executing test "{name}"')


def doRequest(path: str):
    return httpx.get(f'http://localhost:50000{path}')


def removeAllSpaces(text: str):
    return text.replace("\n", "").replace(" ", "")


def executeTest(testName: str, requestPath: str, expectedStatusCode: int, expectedContentType: str, expectedText: str = None, announce: bool = True):
    if announce:
        announceTest(testName)

    r = doRequest(requestPath)
    doAssert("status code", expectedStatusCode, r.status_code)
    doAssert("content type", expectedContentType, r.headers['content-type'])

    if expectedText is not None:
        doAssert("payload text", removeAllSpaces(
            expectedText), removeAllSpaces(r.text))

    if announce:
        announceResult(testName, "PASS!")
    return r


def doAssert(description: str, expectedValue: str, actualValue: str):
    assert actualValue == expectedValue, f'Expected {description} of "{expectedValue}", but got "{actualValue}"'


def announceResult(name: str, result: str):
    print(f'Test "{name}": {result}')


doRequest("/reset")
count = 0

executeTest("xxxx_HealthCheck", "/", 200,
            "text/html; charset=utf-8", "Storefront is ready!")
count += 1

executeTest("3.1.1.1_GetAllProducts", "/catalog", 200, "application/json", json.dumps({
    "CoffeeMug": {
        "configurable": "true"
    },
    "DeskPhone": {
        "configurable": "false"
    },
    "FishingRod": {
        "configurable": "true"
    },
    "Speakers": {
        "configurable": "false"
    },
    "BowlingBall": {
        "configurable": "false"
    },
    "Keyboard": {
        "configurable": "false"
    },
    "Tent": {
        "configurable": "false"
    },
    "Stove": {
        "configurable": "false"
    },
    "Canteen": {
        "configurable": "false"
    },
    "Flashlight": {
        "configurable": "false"
    },
    "Thermostat": {
        "configurable": "false"
    }
}, sort_keys=True))
count += 1

executeTest("3.1.1.1_GetAllConfigurableProducts", "/catalog?configurable=true",
            200, "application/json", json.dumps({
                "CoffeeMug": {
                    "configurable": "true"
                },
                "FishingRod": {
                    "configurable": "true"
                },
            }, sort_keys=True))
count += 1

executeTest("3.1.1.1_GetAllNonConfigurableProducts", "/catalog?configurable=false",
            200, "application/json", json.dumps({
                "DeskPhone": {
                    "configurable": "false"
                },
                "Speakers": {
                    "configurable": "false"
                },
                "BowlingBall": {
                    "configurable": "false"
                },
                "Keyboard": {
                    "configurable": "false"
                },
                "Tent": {
                    "configurable": "false"
                },
                "Stove": {
                    "configurable": "false"
                },
                "Canteen": {
                    "configurable": "false"
                },
                "Flashlight": {
                    "configurable": "false"
                },
                "Thermostat": {
                    "configurable": "false"
                }
            }, sort_keys=True))
count += 1

executeTest("3.1.1.3_ReturnOneConfigurableElement", "/configElements?productName=CoffeeMug",
            200, "application/json", json.dumps({
                "productName": "CoffeeMug",
                "configurableElements":
                [
                    "capacity"
                ]
            }, sort_keys=True))
count += 1

executeTest("3.1.1.3_ReturnMultipleConfigurableElements", "/configElements?productName=FishingRod",
            200, "application/json", json.dumps({
                "productName": "FishingRod",
                "configurableElements":
                [
                    "weight",
                    "length",
                    "material",
                    "strength",
                    "flex"
                ]
            }, sort_keys=True))
count += 1

executeTest("3.1.1.4_UserCanConfigure", "/addConfiguration?productName=FishingRod&configElement=weight",
            200, "application/json", json.dumps({
                "FishingRod":
                [
                    "weight"
                ]
            }, sort_keys=True))
count += 1

executeTest("3.1.1.5_ErrorIfNonConfigurable", "/addConfiguration?productName=DeskPhone&configElement=weight",
            400, "application/json", json.dumps({}))
count += 1

executeTest("3.1.1.6_RetryImmediatelyAfterError", "/addConfiguration?productName=FishingRod&configElement=material",
            200, "application/json", json.dumps({
                "FishingRod":
                [
                    "weight",
                    "material"
                ]
            }, sort_keys=True))
count += 1

executeTest("3.1.2.1_UserSelectsValidProduct", "/details?productName=FishingRod",
            200, "application/json", json.dumps(
                {
                    "productName": "FishingRod",
                    "configurable": "true",
                    "weight": {
                        "amount": "1",
                        "unit": "kilogram"
                    },
                    "length": {
                        "amount": "2",
                        "unit": "meters"
                    },
                    "materials": [
                        "Carbon fiber"
                    ]
                }, sort_keys=True))
count += 1

executeTest("3.1.2.1_UserSelectsInvalidProduct", "/details?productName=Poster",
            200, "application/json", json.dumps(
                {
                }))
count += 1

r = executeTest("3.1.2.2_CatalogSelectionToDetails", "/catalog",
                200, "application/json", expectedText=None, announce=False)
productName = list(json.loads(r.text).keys())[0]
r = executeTest("3.1.2.2_CatalogSelectionToDetails", f"/details?productName={productName}",
                200, "application/json", expectedText=None, announce=False)
count += 1

executeTest("3.1.3.1_DisplayProductCategories", "/categories",
            200, "application/json", json.dumps(
                [
                    "Office",
                    "SportingGoods",
                    "Utility"
                ], sort_keys=True
            ))
count += 1

executeTest("3.1.4.1_SearchAPIExists", "/search?productNameExpression=Coffee.",
            200, "application/json", json.dumps(
                [
                    "CoffeeMug",
                ], sort_keys=True
            ))
count += 1

executeTest("3.1.4.3_ResultsFound", "/search?productNameExpression=[BCD].",
            200, "application/json", json.dumps(
                [
                    "CoffeeMug",
                    "DeskPhone",
                    "BowlingBall",
                    "Canteen",
                ], sort_keys=True
            ))
count += 1

executeTest("3.1.4.4_PaginationLimit", "/search?productNameExpression=.",
            200, "application/json", json.dumps(
                [
                    "CoffeeMug",
                    "DeskPhone",
                    "FishingRod",
                    "Speakers",
                    "BowlingBall",
                    "Keyboard",
                    "Tent",
                    "Stove",
                    "Canteen",
                    "Flashlight"
                ], sort_keys=True
            ))
count += 1

executeTest("3.1.4.6_NoResultsFound", "/search?productNameExpression=Truck",
            200, "application/json", json.dumps([]))
count += 1

executeTest("3.1.5.1_CreateUserProfile", "/createUser?username=John&password=Smith&email=john@smith.edu", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.edu",
            "subscribeForNewsletters": False,
            "subscribeForSurveys": False
            }, sort_keys=True
))
count += 1

executeTest("3.1.5.3_UpdateUserProfile", "/updateUser?username=John&set=email=john@smith.com", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.com",
            "subscribeForNewsletters": False,
            "subscribeForSurveys": False
            }, sort_keys=True
))
count += 1

executeTest("3.1.6.1_DisplayEmptyOrderHistory", "/orderHistory?username=John", 200, "application/json", json.dumps(
    [], sort_keys=True
))
count += 1

executeTest("3.1.6.1_CreateActiveOrder", "/createOrder?username=John&status=Active&productName=CoffeeMug&timestamp=20230110", 200, "application/json", json.dumps(

            {
                "username": "John",
                "status": "Active",
                "productName": "CoffeeMug",
                "timestamp": "20230110"
            }, sort_keys=True
            ))
count += 1

executeTest("3.1.6.1_CreateCompletedOrder", "/createOrder?username=John&status=Completed&productName=FishingRod&timestamp=20230110", 200, "application/json", json.dumps(

            {
                "username": "John",
                "status": "Completed",
                "productName": "FishingRod",
                "timestamp": "20230110"
            }, sort_keys=True
            ))
count += 1

executeTest("3.1.6.1_DisplayPopulatedOrderHistoryAll", "/orderHistory?username=John", 200, "application/json", json.dumps(
    [{
        "username": "John",
        "status": "Active",
        "productName": "CoffeeMug",
        "timestamp": "20230110"
    },
        {
        "username": "John",
        "status": "Completed",
        "productName": "FishingRod",
        "timestamp": "20230110"
    }
    ], sort_keys=True
))
count += 1

executeTest("3.1.6.1_DisplayPopulatedOrderHistoryActive", "/orderHistory?username=John&status=Active", 200, "application/json", json.dumps(
    [{
        "username": "John",
        "status": "Active",
        "productName": "CoffeeMug",
        "timestamp": "20230110"
    }], sort_keys=True
))
count += 1

executeTest("3.1.6.1_DisplayPopulatedOrderHistoryCompleted", "/orderHistory?username=John&status=Completed", 200, "application/json", json.dumps(
    [{
            "username": "John",
            "status": "Completed",
            "productName": "FishingRod",
            "timestamp": "20230110"
            }], sort_keys=True
))
count += 1

executeTest("3.1.6.3_DisplayOrderDetailsForValidOrder", "/orderDetails?username=John&productName=CoffeeMug&timestamp=20230110", 200, "application/json", json.dumps(
    {
        "key" : "John_CoffeeMug_20230110",
        "orderDetails": "Some more information about the order."
            }, sort_keys=True
))
count += 1

executeTest("3.1.6.3_DisplayErrorForInvalidOrder", "/orderDetails?username=John&productName=FishingRod&timestamp=Never", 400, "application/json", json.dumps(
    {}, sort_keys=True
))
count += 1

executeTest("3.1.6.5_RegisterForNewsletters", "/updateUser?username=John&set=subscribeForNewsletters=True", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.com",
            "subscribeForNewsletters": True,
            "subscribeForSurveys": False
            }, sort_keys=True
))
count += 1

executeTest("3.1.6.5_RegisterForNewsletters", "/updateUser?username=John&set=subscribeForSurveys=True", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.com",
            "subscribeForNewsletters": True,
            "subscribeForSurveys": True
            }, sort_keys=True
))
count += 1

executeTest("3.1.7.1_GeneralHelpRequested", "/help", 200, "text/html; charset=utf-8", "Here's some useful info!")
count += 1

executeTest("3.1.7.3_SupportAPI", "/support?username=Frank&productName=TackleBox", 200, "application/json", json.dumps(
    {
        "username" : "Frank",
        "productName" : "TackleBox"
    }, sort_keys=True
))
count += 1

print(f'Successfully executed all {count} tests!')
