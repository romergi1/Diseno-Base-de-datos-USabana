db.products.find({ 'category': 'electronics' }).limit(5)
db.orders.find({ 'total_amount': { $gt: 100 } }, { 'order_id': 1, 'total_amount': 1, '_id': 0 }).limit(5)
db.products.aggregate([
    { $group: { _id: '$category', count: { $sum: 1 } } },
    { $sort: { count: -1 } }
]).limit(5)
db.customers.find({ 'address.city': 'New York', 'address.state': 'NY' }).limit(5)
db.orders.aggregate([
    { $match: { 'status': 'completed' } },
    { $group: { _id: { $dateToString: { format: '%Y-%m', date: '$order_date' } }, totalSales: { $sum: '$total_amount' } } },
    { $sort: { _id: 1 } }
]).limit(5)
db.reviews.find({ 'rating': 5 }).sort({ 'review_date': -1 }).limit(5)

db.products.insertOne({
    "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b1"),
    "name": "Smartwatch Pro",
    "category": "electronics",
    "price": 199.99,
    "stock": 50,
    "description": "Advanced smartwatch with health tracking and notifications."
})
db.customers.insertOne({
    "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b2"),
    "name": "Alice Wonderland",
    "email": "alice.w@example.com",
    "address": {
        "street": "123 Rabbit Hole",
        "city": "Wonderland",
        "state": "AZ",
        "zip": "85001"
    },
    "registration_date": ISODate("2023-01-15T10:00:00Z")
})
db.orders.insertOne({
    "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b3"),
    "customer_id": ObjectId("65d496c1d4a0a4c2f4e3c2b2"),
    "order_date": ISODate("2023-06-01T14:30:00Z"),
    "status": "pending",
    "total_amount": 219.98,
    "items": [
        {
            "product_id": ObjectId("65d496c1d4a0a4c2f4e3c2b1"),
            "quantity": 1,
            "price": 199.99
        },
        {
            "product_id": ObjectId("65d496c1d4a0a4c2f4e3c2b4"), # Hypothetical new product ID
            "quantity": 1,
            "price": 19.99
        }
    ]
})
db.reviews.insertMany([
    {
        "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b5"),
        "product_id": ObjectId("65d496c1d4a0a4c2f4e3c2b1"),
        "customer_id": ObjectId("65d496c1d4a0a4c2f4e3c2b2"),
        "rating": 5,
        "comment": "Absolutely love this smartwatch! Great features and battery life.",
        "review_date": ISODate("2023-06-05T09:00:00Z")
    },
    {
        "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b6"),
        "product_id": ObjectId("65d496c1d4a0a4c2f4e3c2b1"),
        "customer_id": ObjectId("65d496c1d4a0a4c2f4e3c2b7"), # Hypothetical new customer ID
        "rating": 4,
        "comment": "Good product, but a bit pricey.",
        "review_date": ISODate("2023-06-07T11:20:00Z")
    }
])

db.products.updateOne(
    { "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b1") },
    { $set: { "price": 209.99, "stock": 45 } }
)
db.orders.updateOne(
    { "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b3"), "status": "pending" },
    { $set: { "status": "processing", "processing_date": ISODate("2023-06-02T10:00:00Z") } }
)
db.orders.updateOne(
    { "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b3") },
    { $push: { "items": { "product_id": ObjectId("65d496c1d4a0a4c2f4e3c2b8"), "quantity": 1, "price": 5.99 } } }
)
db.orders.updateOne(
    { "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b3") },
    { $inc: { "total_amount": 5.99 } }
)
db.reviews.updateOne(
    { "_id": ObjectId("65d496c1d4a0a4c2f4e3c2b5") },
    { $set: { "comment": "Still loving this smartwatch! Battery life is exceptional.", "review_date": ISODate("2023-07-10T15:00:00Z") } }
)