import argparse
import httpx
import json
import os
import tempfile
from datetime import datetime, timezone

parser = argparse.ArgumentParser()
parser.add_argument('--ledgerURL', required=False)
args = parser.parse_args()

ledgerURL = args.ledgerURL
tempdir = tempfile.gettempdir()

count = 0


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
        global count
        count += 1

    global ledgerURL, tempdir
    if ledgerURL is not None:
        print(f"Reporting results to ledger at {ledgerURL}.")
        
        allArtifactsEndpoint=f'{ledgerURL}/artifacts/listAllArtifacts'
        r = httpx.get(allArtifactsEndpoint)
        allArtifacts = json.loads(r.text)
        # Find the matching requirement.
        requirementID=testName.split("_")[0]
        print(f'Locating requirement {requirementID}')
        requirementIPFSName=None
        for artifact in allArtifacts["result"]:
            if artifact["ID"] == f'{requirementID}.requirement':
                requirementIPFSName = artifact["IPFSName"]
                print(f'IPFS for requirement {requirementID} is {requirementIPFSName}')
                break
        
        filename=os.path.join(tempdir, f'{testName}.result')
        with open(filename, 'w') as f:
            f.writelines([testName, os.linesep, datetime.now(timezone.utc).isoformat(), os.linesep, "PASS!"])
        
        createArtifactEndpoint=f'{ledgerURL}/artifacts/createArtifact'

        # Upload the result artifact.
        resultIPFSName = None
        with open(filename, 'rb') as f:
            files = {'upfile': (filename, f, 'multipart/form-data')}
            r = httpx.post(createArtifactEndpoint, files=files)
            print(r.status_code)
            print(r.text)
            resultIPFSName = json.loads(r.text)["result"]["result"]["IPFSName"]
        
        # Relate the artifact to its parent requirement artifact.
        createRelationshipEndpoint=f'{ledgerURL}/relationships/createRelationship'
        print(f'Relating requirement {requirementIPFSName} to result {resultIPFSName}')
        data = { "nodeida": f"{requirementIPFSName}", "nodeidb" : f"{resultIPFSName}"}
        r = httpx.post(createRelationshipEndpoint, json=data)
        print(r.status_code)
        print(r.text)

    return r


def doAssert(description: str, expectedValue: str, actualValue: str):
    assert actualValue == expectedValue, f'Expected {description} of "{expectedValue}", but got "{actualValue}"'


def announceResult(name: str, result: str):
    print(f'Test "{name}": {result}')


startTime = datetime.now(timezone.utc)

# Note: These tests are intended to execute sequentially and, in some cases,
#       the results of one influence the results of another if stored state
#       is involved (such as orders)

doRequest("/reset")
count = 0

executeTest("3.4.1_PerformReadinessCheck", "/", 200,
            "text/html; charset=utf-8", "Storefront is ready!")

executeTest("3.4.1_PerformHealthCheck", "/health", 200,
            "text/html; charset=utf-8", "Storefront is healthy!")

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


executeTest("3.1.1.1_GetAllConfigurableProducts", "/catalog?configurable=true",
            200, "application/json", json.dumps({
                "CoffeeMug": {
                    "configurable": "true"
                },
                "FishingRod": {
                    "configurable": "true"
                },
            }, sort_keys=True))


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


executeTest("3.1.1.3_ReturnOneConfigurableElement", "/configElements?productName=CoffeeMug",
            200, "application/json", json.dumps({
                "productName": "CoffeeMug",
                "configurableElements":
                [
                    "capacity"
                ]
            }, sort_keys=True))


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


executeTest("3.1.1.4_UserCanConfigure", "/addConfiguration?productName=FishingRod&configElement=weight",
            200, "application/json", json.dumps({
                "FishingRod":
                [
                    "weight"
                ]
            }, sort_keys=True))


executeTest("3.1.1.5_ErrorIfNonConfigurable", "/addConfiguration?productName=DeskPhone&configElement=weight",
            400, "application/json", json.dumps({}))


executeTest("3.1.1.6_RetryImmediatelyAfterError", "/addConfiguration?productName=FishingRod&configElement=material",
            200, "application/json", json.dumps({
                "FishingRod":
                [
                    "weight",
                    "material"
                ]
            }, sort_keys=True))


executeTest("3.1.2.1_DisplayDetailsForValidProduct", "/details?productName=FishingRod",
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


executeTest("3.1.2.1_ReturnErrorForInvalidProduct", "/details?productName=Poster",
            200, "application/json", json.dumps(
                {
                }))


r = executeTest("3.1.2.2_CatalogSelectionToDetails", "/catalog",
                200, "application/json", expectedText=None, announce=False)
productName = list(json.loads(r.text).keys())[0]
r = executeTest("3.1.2.2_CatalogSelectionToDetails", f"/details?productName={productName}",
                200, "application/json", expectedText=None)


executeTest("3.1.3.1_DisplayProductCategories", "/categories",
            200, "application/json", json.dumps(
                [
                    "Office",
                    "SportingGoods",
                    "Utility"
                ], sort_keys=True
            ))


executeTest("3.1.4.1_SearchAPIExists", "/search?productNameExpression=Coffee.",
            200, "application/json", json.dumps(
                [
                    "CoffeeMug",
                ], sort_keys=True
            ))


executeTest("3.1.4.3_ResultsFound", "/search?productNameExpression=[BCD].",
            200, "application/json", json.dumps(
                [
                    "CoffeeMug",
                    "DeskPhone",
                    "BowlingBall",
                    "Canteen",
                ], sort_keys=True
            ))


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


executeTest("3.1.4.6_NoResultsFound", "/search?productNameExpression=Truck",
            200, "application/json", json.dumps([]))


executeTest("3.1.5.1_CreateUserProfile", "/createUser?username=John&password=Smith&email=john@smith.edu", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.edu",
            "subscribeForNewsletters": False,
            "subscribeForSurveys": False,
            "contactNumber": ""
            }, sort_keys=True
))


executeTest("3.1.5.3_UpdateUserProfile", "/updateUser?username=John&set=email=john@smith.com", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.com",
            "subscribeForNewsletters": False,
            "subscribeForSurveys": False,
            "contactNumber": ""
            }, sort_keys=True
))


executeTest("3.1.6.1_DisplayEmptyOrderHistory", "/orderHistory?username=John", 200, "application/json", json.dumps(
    [], sort_keys=True
))


executeTest("3.1.6.1_CreateActiveOrder", "/createOrder?username=John&status=Active&productName=CoffeeMug&timestamp=20230110", 200, "application/json", json.dumps(

            {
                "username": "John",
                "status": "Active",
                "productName": "CoffeeMug",
                "timestamp": "20230110"
            }, sort_keys=True
            ))


executeTest("3.1.6.1_CreateCompletedOrder", "/createOrder?username=John&status=Completed&productName=FishingRod&timestamp=20230110", 200, "application/json", json.dumps(

            {
                "username": "John",
                "status": "Completed",
                "productName": "FishingRod",
                "timestamp": "20230110"
            }, sort_keys=True
            ))


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


executeTest("3.1.6.1_DisplayPopulatedOrderHistoryActive", "/orderHistory?username=John&status=Active", 200, "application/json", json.dumps(
    [{
        "username": "John",
        "status": "Active",
        "productName": "CoffeeMug",
        "timestamp": "20230110"
    }], sort_keys=True
))


executeTest("3.1.6.1_DisplayPopulatedOrderHistoryCompleted", "/orderHistory?username=John&status=Completed", 200, "application/json", json.dumps(
    [{
            "username": "John",
            "status": "Completed",
            "productName": "FishingRod",
            "timestamp": "20230110"
            }], sort_keys=True
))

executeTest("3.1.6.3_DisplayOrderDetailsForValidOrder", "/orderDetails?username=John&productName=CoffeeMug&timestamp=20230110", 200, "application/json", json.dumps(
    {
        "key": "John_CoffeeMug_20230110",
        "orderDetails": "Some more information about the order.",
        "trackingInfo": "Some tracking info here",
        "taxInfo": "Some tax info"
    }, sort_keys=True
))

executeTest("3.1.6.3_DisplayErrorForInvalidOrder", "/orderDetails?username=John&productName=FishingRod&timestamp=Never", 400, "application/json", json.dumps(
    {}, sort_keys=True
))

executeTest("3.1.6.5_RegisterForNewsletters", "/updateUser?username=John&set=subscribeForNewsletters=True", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.com",
            "subscribeForNewsletters": True,
            "subscribeForSurveys": False,
            "contactNumber": ""
            }, sort_keys=True
))

executeTest("3.1.6.5_RegisterForSurveys", "/updateUser?username=John&set=subscribeForSurveys=True", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.com",
            "subscribeForNewsletters": True,
            "subscribeForSurveys": True,
            "contactNumber": ""
            }, sort_keys=True
))

executeTest("3.1.7.1_GeneralHelpRequested", "/help", 200,
            "text/html; charset=utf-8", "Here's some useful info!")

executeTest("3.1.7.3_SupportAPI", "/support?username=Frank&productName=TackleBox", 200, "application/json", json.dumps(
    {
        "username": "Frank",
        "productName": "TackleBox"
    }, sort_keys=True
))

executeTest("3.1.7.4_GetCustomerSupportNumbers", "/customerSupport", 200, "application/json", json.dumps(
    {
        "GeneralHelp": "1-800-555-HELP",
        "Sales": "1-800-55SALES",
        "TechnicalSupport": "1-800-555-TECH",
        "Returns": "1-800-4RETURNS"
    }, sort_keys=True
))

executeTest("3.1.7.5_CallbackNumberInProfile", "/updateUser?username=John&set=contactNumber=1-814-4JSMITH", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.com",
            "subscribeForNewsletters": True,
            "subscribeForSurveys": True,
            "contactNumber": "1-814-4JSMITH"
            }, sort_keys=True
))

executeTest("3.1.7.6_DetailedHelpRequested", "/help?detailed=True", 200, "application/json", json.dumps(
    {
            "System": "Marvel Electronics and Home Entertainment Storefront",
            "Purpose": "Case study implementation of a public Software Requirements Specification (SRS) in support of ChaordicLedger validation for PhD dissertation."
            }, sort_keys=True
))

executeTest("3.1.7.7_FAQRequested", "/faq", 200, "application/json", json.dumps(
    {
            "1": {
                "Question": "How much wood would a woodchuck chuck if a woodchuck could chuck wood?",
                "Answer": "Probably a lot."
            },
            "2": {
                "Question": "What is the answer to the ultimate question?",
                "Answer": "42!"
            },
            "3": {
                "Question": "What does FAQ mean?",
                "Answer": "Frequently Asked Questions."
            }
            }, sort_keys=True
))

executeTest("3.1.8.1_UserEmailInProfile", "/profile?user=John", 200, "application/json", json.dumps(
    {
            "username": "John",
            "email": "john@smith.com",
            "subscribeForNewsletters": True,
            "subscribeForSurveys": True,
            "contactNumber": "1-814-4JSMITH"
            }, sort_keys=True
))

executeTest("3.1.8.1_UserDoesNotExist", "/profile?user=Jim",
            400, "application/json", json.dumps({}))

executeTest("3.1.10.1_DisplayEmptyCart", "/viewCart",
            200, "application/json", json.dumps([]))

executeTest("3.1.10.1_DisplayPopulatedCart", "/addToCart?item=FishingRod",
            200, "application/json", json.dumps(["FishingRod"]), announce=False)
executeTest("3.1.10.1_DisplayPopulatedCart", "/viewCart", 200,
            "application/json", json.dumps(["FishingRod"]))
executeTest("3.1.10.1_DisplayPopulatedCart", "/removeFromCart?item=FishingRod",
            200, "application/json", json.dumps([]), announce=False)

executeTest("3.1.10.2_AddItemsToCart", "/addToCart?item=DeskPhone",
            200, "application/json", json.dumps(["DeskPhone"]))
executeTest("3.1.10.2_RemoveFromCart", "/removeFromCart?item=DeskPhone",
            200, "application/json", json.dumps([]))

executeTest("3.1.10.2_ErrorOnRemoveItemsFromEmpty",
            "/removeFromCart?item=DeskPhone", 400, "application/json", json.dumps([]))

executeTest("3.1.10.2_ErrorOnRemoveInvalidItem", "/addToCart?item=FishingRod",
            200, "application/json", json.dumps(["FishingRod"]), announce=False)
executeTest("3.1.10.2_ErrorOnRemoveInvalidItem",
            "/removeFromCart?item=Compass", 400, "application/json", json.dumps([]))

executeTest("3.1.10.2_ErrorOnRemoveNonExistentItem",
            "/removeFromCart?item=Statue", 400, "application/json", json.dumps([]))

executeTest("3.1.11.1_GetShippingOptions", "/shippingOptions", 200, "application/json", json.dumps(
    [
        "Drone",
        "CarrierPigeon",
        "IndependentContractor",
        "In-Store"
    ], sort_keys=True
))

executeTest("3.1.11.3_GetShippingCharges", "/shippingCharges", 200, "application/json", json.dumps(
    {
        "Drone": "$5",
        "CarrierPigeon": "$7",
        "IndependentContractor": "$10",
        "In-Store": "$0"
    }, sort_keys=True
))

executeTest("3.1.11.4_GetShippingDuration", "/shippingDurations", 200, "application/json", json.dumps(
    {
        "Drone": "1 hour",
        "CarrierPigeon": "4 hours",
        "IndependentContractor": "0.5 hours",
        "In-Store": "0 hours"
    }, sort_keys=True
))

executeTest("3.1.14.1_GetPaymentMethods", "/paymentMethods", 200, "application/json", json.dumps(
    [
        "Cash on delivery",
        "Credit Card",
        "Third party",
        "Barter / Trade"
    ], sort_keys=True
))

executeTest("3.1.15.3_CancelActiveOrder", "/cancelOrder?username=John&productName=CoffeeMug&timestamp=20230110", 200, "application/json", json.dumps(
    {
        "username": "John",
        "status": "Cancelled",
        "productName": "CoffeeMug",
        "timestamp": "20230110"
    }, sort_keys=True
))

executeTest("3.1.15.3_CancelCancelledOrder", "/cancelOrder?username=John&productName=CoffeeMug&timestamp=20230110", 200, "application/json", json.dumps(
    {
        "username": "John",
        "status": "Cancelled",
        "productName": "CoffeeMug",
        "timestamp": "20230110"
    }, sort_keys=True
))

executeTest("3.1.15.4_ModifyOrderShipping", "/updateOrder?username=John&productName=CoffeeMug&timestamp=20230110&set=shipping=Drone", 200, "application/json", json.dumps(
    {
        "username": "John",
        "status": "Cancelled",
        "productName": "CoffeeMug",
        "timestamp": "20230110",
        "shipping": "Drone"
    }, sort_keys=True
))

executeTest("3.1.15.4_ModifyOrderPaymentMethod", "/updateOrder?username=John&productName=CoffeeMug&timestamp=20230110&set=paymentMethod=Barter", 200, "application/json", json.dumps(
    {
        "username": "John",
        "status": "Cancelled",
        "productName": "CoffeeMug",
        "timestamp": "20230110",
        "shipping": "Drone",
        "paymentMethod": "Barter"
    }, sort_keys=True
))

executeTest("3.1.16.1_GetProductReviews", "/productReviews", 200, "application/json", json.dumps(
    {
        "FishingRod": [
            "Best ever!",
            "A great gift!",
            "Durable! I've tried to break it, but I can't!"
        ],
        "CoffeeMug": [
            "It's a mug.",
            "I like coffee.",
        ],
        "DeskPhone": [
            "It's a phone.",
        ]
    }, sort_keys=True
))

executeTest("3.1.17.1_GetFinancingOptions", "/financingOptions", 200, "application/json", json.dumps(
    [
        "A credit union",
        "A bank",
        "A loan shark",
        "Predatory loans"
    ], sort_keys=True
))

executeTest("3.1.19.1_GetAvailablePromotions", "/promotions", 200, "application/json", json.dumps(
    [
        "Buy one fishing rod, get one half off!",
        "Buy two coffee mugs, get the third for half off!"
    ], sort_keys=True
))

endTime = datetime.now(timezone.utc)

print(f'Successfully executed all {count} tests in {endTime - startTime}!')
