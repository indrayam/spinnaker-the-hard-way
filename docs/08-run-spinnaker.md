# Run Spinnaker

## Update Base URLs for Spinnaker UI (spin-deck) and API Gateway (spin-gate)

With the Spinnaker Ingress objects configured, all you need to do to complete Spinnaker install is to let Halyard know about the Ingress details:

```bash
hal config security ui edit \
    --override-base-url https://spinnaker1-code.cisco.com

hal config security api edit \
    --override-base-url https://spinnaker1api-code.cisco.com
```

Deploy Spinnaker:

```
hal deploy apply
```

Connect to Spinnaker by opening a browser window to `spinnaker1-code.cisco.com`
