# cashew_marketplace

## API Notes
### Android Bundle Build
  To fetch play store Build use (flutter build appbundle --release) 
  To Re-Auth the Key (Valdiate for 27 years) TO Create (Password KT@2022)
    keytool -genkeypair -v \
        -keystore android/app/key.jks \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -alias market-place-kajupro

  to verify the 
  keytool -list -v -keystore android/app/key.jks                    

  To Delete the key 
    keytool -delete -alias market-place-kajupro -keystore android/app/key.jks      

## To Find the what are persmission required for apk/bundle 
    aapt => find ~/Library/Android/sdk -name aapt (MAC)          
    aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
## To Find the What are package use which permission
    Step 1 => cd android
    step 2 => change the gradle.properties`
                org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -Dfile.encoding=UTF-8
                android.useAndroidX=true
                android.enableJetifier=true
              `
    Step 3 => ./gradlew app:dependencies > deps.txt (It constatins hierarchy of service used)