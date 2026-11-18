resource "aws_dynamodb_table" "dynamodb-table" {
  for_each     = var.dynamodb_tables
  name         = "${var.application_name}-${each.value.name-suffix}"
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

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }
}
