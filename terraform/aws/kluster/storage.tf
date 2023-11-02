# resource "aws_s3_bucket" "storage" {
#   bucket        = "bucket-${var.sid}-${var.tenant}-${var.env}"
#   force_destroy = true
# }

# resource "aws_s3_bucket_ownership_controls" "storage" {
#   bucket = aws_s3_bucket.storage.id
#   rule {
#     object_ownership = "ObjectWriter"
#   }
# }

# resource "aws_s3_bucket_acl" "storage" {
#   depends_on = [aws_s3_bucket_ownership_controls.storage]
#   bucket     = aws_s3_bucket.storage.id
#   acl        = "private"
# }

# resource "aws_s3_bucket_cors_configuration" "storage" {
#   bucket = aws_s3_bucket.storage.id

#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET", "POST", "DELETE", "PUT", "HEAD"]
#     allowed_origins = ["*"]
#     expose_headers  = ["ETag", "x-amz-request-id"]
#     max_age_seconds = 3000
#   }
# }

# resource "aws_iam_policy" "allow_storage_bucket_all_actions" {
#   name = "s3-all-actions-${aws_s3_bucket.storage.id}"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         "Sid" : "ListObjectsInBucket",
#         "Effect" : "Allow",
#         "Action" : ["s3:ListBucket"],
#         "Resource" : [aws_s3_bucket.storage.arn]
#       },
#       {
#         "Sid" : "AllObjectActions",
#         "Effect" : "Allow",
#         "Action" : "s3:*Object",
#         "Resource" : ["${aws_s3_bucket.storage.arn}/*"]
#       }
#     ]
#   })
# }

# resource "aws_s3_bucket_lifecycle_configuration" "storage" {
#   bucket = aws_s3_bucket.storage.id
#   rule {
#     id = "logs"
#     filter {
#       prefix = "logs/"
#     }
#     expiration {
#       days = 30
#     }
#     status = "Enabled"
#   }
# }
