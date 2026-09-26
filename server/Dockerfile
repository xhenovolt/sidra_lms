# Sidra payments server: a small always-on process.
#   docker build -t sidra-payments server/
#   docker run -e PAYMENTS_DATABASE_URL=… -e MARZPAY_API_KEY=… \
#              -e MARZPAY_API_SECRET=… -e PUBLIC_URL=https://… -p 8080:8080 sidra-payments
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/payments_server.dart -o /app/payments_server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/payments_server /app/payments_server
EXPOSE 8080
ENTRYPOINT ["/app/payments_server"]
