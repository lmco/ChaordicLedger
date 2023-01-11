from flask import Flask, request, Response
import json
import re

app = Flask(__name__)

# These global variable represent what would be stateful data in a production deployment.
globalConfiguration = {}
globalUserProfiles = {}
globalOrderHistory = {}
globalOrderDetailsHistory = {}
globalCart = []


@app.route('/')
def index():
  return 'Storefront is ready!'


@app.route('/health')
def health():
  return 'Storefront is healthy!'


@app.route('/reset')
def reset():
  global globalConfiguration
  globalConfiguration.clear()

  global globalUserProfiles
  globalUserProfiles.clear()

  global globalOrderHistory
  globalOrderHistory.clear()

  global globalOrderDetailsHistory
  globalOrderDetailsHistory.clear()

  global globalCart
  globalCart.clear()

  return 'Reset complete!'


@app.route('/catalog')
def catalog():
  configurable = request.args.get('configurable')

  retval = None
  with open("products.json", "r") as f:
    retval = json.load(f)

  if configurable == "true" or configurable == "false":
    subset = {}

    for key in retval.keys():
      if retval[key]["configurable"] == configurable:
        subset[key] = retval[key]

    retval = subset

  return retval


@app.route('/details')
def details():
  productName = request.args.get('productName')

  retval = {}
  with open("details.json", "r") as f:
    details = json.load(f)

  for key in details.keys():
    if key == productName:
      retval = details[key]

  return retval


@app.route('/configElements')
def configElements():
  productName = request.args.get('productName')

  retval = {}
  with open("configurableElements.json", "r") as f:
    configurableElements = json.load(f)

  for key in configurableElements.keys():
    if key == productName:
      retval = configurableElements[key]

  return retval


@app.route('/addConfiguration')
def addConfiguration():
  productName = request.args.get('productName')

  catalog = {}
  with open("products.json", "r") as f:
    catalog = json.load(f)

  if productName in catalog.keys() and catalog[productName]["configurable"] == "true":
    configElement = request.args.get('configElement')

    if productName not in globalConfiguration:
      globalConfiguration[productName] = []

    globalConfiguration[productName].append(configElement)
    return globalConfiguration

  return Response("{}", 400, mimetype='application/json')


@app.route('/removeConfiguration')
def removeConfiguration():
  productName = request.args.get('productName')

  catalog = {}
  with open("products.json", "r") as f:
    catalog = json.load(f)

  if productName in catalog.keys() and catalog[productName]["configurable"] == "true":
    configElement = request.args.get('configElement')

    if productName not in globalConfiguration:
      globalConfiguration[productName] = []

    globalConfiguration[productName].remove(configElement)
    return globalConfiguration

  return Response("{}", 400, mimetype='application/json')


@app.route('/categories')
def categories():
  retval = {}
  with open("categories.json", "r") as f:
    retval = json.load(f)

  return retval


@app.route('/search')
def search():
  pattern = request.args.get('productNameExpression')

  products = None
  with open("products.json", "r") as f:
    products = json.load(f)

  limit = 10
  retval = []
  for item in products.keys():
    match = re.match(pattern, item)
    if match is not None:
      retval.append(item)
      if len(retval) == limit:
        break

  return retval


@app.route('/createUser')
def createUser():
  username = request.args.get('username')
  password = request.args.get('password')
  email = request.args.get('email')

  userProfile = {
      "username": {
          "value": username,
          "sensitive": False,
      },
      "password": {
          "value": password,
          "sensitive": True,
      },
      "email": {
          "value": email,
          "sensitive": False,
      },
      "contactNumber": {
          "value": "",
          "sensitive": False
      },
      "subscribeForNewsletters": {
          "value": False,
          "sensitive": False,
      },
      "subscribeForSurveys": {
          "value": False,
          "sensitive": False,
      },
  }

  globalUserProfiles[username] = userProfile

  return sanitizeProfile(userProfile)


def sanitizeProfile(userProfile: dict):
  retval = {}
  for key in userProfile.keys():
    item = userProfile[key]
    if item["sensitive"] == False:
      retval[key] = item["value"]

  return retval


@app.route('/updateUser')
def updateUser():
  username = request.args.get('username')
  expression = request.args.get('set')

  if username in globalUserProfiles:
    userProfile = globalUserProfiles[username]

    parts = expression.split("=")

    value = parts[1]

    if value == "True":
      value = True
    elif value == "False":
      value = False

    if parts[0] in userProfile:
      userProfile[parts[0]] = {
          "value": value,
          "sensitive": False
      }

  return sanitizeProfile(userProfile)


@app.route('/orderHistory')
def orderHistory():
  username = request.args.get('username')
  status = request.args.get('status')

  retval = []

  if username in globalOrderHistory:
    allOrders = globalOrderHistory[username]

    if status == "Active" or status == "Completed":
      for i in range(0, len(allOrders)):
        if allOrders[i]["status"] == status:
          retval.append(allOrders[i])
    else:
      retval = allOrders

  return retval


@app.route('/createOrder')
def createOrder():
  username = request.args.get('username')
  status = request.args.get('status')
  productName = request.args.get('productName')
  timestamp = request.args.get('timestamp')

  if username not in globalOrderHistory:
    globalOrderHistory[username] = []

  order = {
      "username": username,
      "status": status,
      "productName": productName,
      "timestamp": timestamp
  }

  globalOrderHistory[username].append(order)

  if username not in globalOrderDetailsHistory:
    globalOrderDetailsHistory[username] = {}

  globalOrderDetailsHistory[username][f"{username}_{productName}_{timestamp}"] = {
      "key": f"{username}_{productName}_{timestamp}",
      "orderDetails": "Some more information about the order.",
      "trackingInfo": "Some tracking info here",
      "taxInfo": "Some tax info"
  }

  return order


@app.route('/orderDetails')
def orderDetails():
  username = request.args.get('username')
  productName = request.args.get('productName')
  timestamp = request.args.get('timestamp')

  key = f"{username}_{productName}_{timestamp}"
  if username in globalOrderDetailsHistory and key in globalOrderDetailsHistory[username]:
    return globalOrderDetailsHistory[username][key]

  return Response("{}", 400, mimetype='application/json')


@app.route('/help')
def help():
  detailed = request.args.get('detailed')

  retval = "Here's some useful info!"

  if detailed == "True":
    retval = {
        "System": "Marvel Electronics and Home Entertainment Storefront",
        "Purpose": "Case study implementation of a public Software Requirements Specification (SRS) in support of ChaordicLedger validation for PhD dissertation."
    }

  return retval


@app.route('/support')
def support():
  username = request.args.get('username')
  productName = request.args.get('productName')
  return {
      "username": username,
      "productName": productName
  }


@app.route('/customerSupport')
def customerSupport():
  return {
      "GeneralHelp": "1-800-555-HELP",
      "Sales": "1-800-55SALES",
      "TechnicalSupport": "1-800-555-TECH",
      "Returns": "1-800-4RETURNS"
  }


@app.route('/faq')
def faq():
  return {
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
  }


@app.route('/profile')
def profile():
  username = request.args.get('user')

  if username in globalUserProfiles:
    return sanitizeProfile(globalUserProfiles[username])

  return Response("{}", 400, mimetype='application/json')


@app.route('/viewCart')
def viewCart():
  return globalCart


@app.route('/addToCart')
def addToCart():
  item = request.args.get('item')
  globalCart.append(item)
  return globalCart


@app.route('/removeFromCart')
def removeFromCart():
  item = request.args.get('item')

  if item in globalCart:
    globalCart.remove(item)
    return globalCart

  return Response("[]", 400, mimetype='application/json')


@app.route('/shippingOptions')
def shippingOptions():
  return [
      "Drone",
      "CarrierPigeon",
      "IndependentContractor",
      "In-Store"
  ]


@app.route('/shippingCharges')
def shippingCharges():
  return {
      "Drone": "$5",
      "CarrierPigeon": "$7",
      "IndependentContractor": "$10",
      "In-Store": "$0"
  }


@app.route('/shippingDurations')
def shippingDurations():
  return {
      "Drone": "1 hour",
      "CarrierPigeon": "4 hours",
      "IndependentContractor": "0.5 hours",
      "In-Store": "0 hours"
  }


@app.route('/paymentMethods')
def paymentMethods():
  return [
      "Cash on delivery",
      "Credit Card",
      "Third party",
      "Barter / Trade"
  ]


@app.route('/cancelOrder')
def cancelOrder():
  username = request.args.get('username')
  productName = request.args.get('productName')
  timestamp = request.args.get('timestamp')

  if username in globalOrderHistory:
    retval = None
    for order in globalOrderHistory[username]:
      if order["productName"] == productName and order["timestamp"] == timestamp:
        order["status"] = "Cancelled"
        retval = order
      break

    if retval is None:
      return Response("{}", 400, mimetype='application/json')

    return retval

  return Response("{}", 400, mimetype='application/json')


@app.route('/updateOrder')
def updateOrder():
  username = request.args.get('username')
  productName = request.args.get('productName')
  timestamp = request.args.get('timestamp')
  expression = request.args.get('set')

  if username in globalOrderHistory:
    retval = None
    for order in globalOrderHistory[username]:
      if order["productName"] == productName and order["timestamp"] == timestamp:
        # Note: in production, user input needs to be validated.
        parts = expression.split("=")
        order[parts[0]] = parts[1]
        retval = order
      break

    if retval is None:
      return Response("{}", 400, mimetype='application/json')

    return retval

  return Response("{}", 400, mimetype='application/json')


@app.route('/productReviews')
def productReviews():
  return {
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
  }


@app.route('/financingOptions')
def financingOptions():
  return [
      "A credit union",
      "A bank",
      "A loan shark",
      "Predatory loans"
  ]


@app.route('/promotions')
def promotions():
  return [
      "Buy one fishing rod, get one half off!",
      "Buy two coffee mugs, get the third for half off!"
  ]


if __name__ == '__main__':
	app.run(host='0.0.0.0', port=50000)
