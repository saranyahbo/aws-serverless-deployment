resource "aws_dynamodb_table" "dynamodb-table" {
  for_each     = var.dynamodb_tables
  name         = "${var.application_name}-${each.value["name-suffix"]}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = each.value.hash_key
  range_key    = each.value.range_key
  dynamic "attribute" {
    for_each = each.value.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

}

locals {
  product_catalog = {
    for product in jsondecode(file("${path.module}/data/products.json")) : product.productId => product
  }
}

resource "aws_dynamodb_table_item" "product_catalog" {
  for_each   = local.product_catalog
  table_name = aws_dynamodb_table.dynamodb-table["products"].name
  hash_key   = "productId"

  item = jsonencode({
    productId   = { S = each.value.productId }
    id          = { N = tostring(each.value.id) }
    name        = { S = each.value.name }
    category    = { S = each.value.category }
    price       = { N = tostring(each.value.price) }
    oldPrice    = try(each.value.oldPrice, null) == null ? { NULL = true } : { N = tostring(each.value.oldPrice) }
    rating      = { N = tostring(each.value.rating) }
    reviews     = { N = tostring(each.value.reviews) }
    badge       = { S = each.value.badge }
    description = { S = each.value.description }
    image       = { S = each.value.image }
    alt         = { S = each.value.alt }
    stock       = { N = tostring(each.value.stock) }
  })
}
