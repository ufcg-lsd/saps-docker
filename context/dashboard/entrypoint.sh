#!/bin/bash

pm2 start /dashboard/app.js
service nginx restart
pm2 logs app