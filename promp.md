Bir arkadaşlık uygulaması yapacağız, uygulamanın front end kısmı flutter ile, back end kısmı django ile yapılacak, veritabanı için ise sqllite kullanacağız.
Uygulamada bir login ekranı olacak, google ile giriş yapma özelliği olacak, kullanıcı fotoğrafını ve ismini google dan alacak
İki tür kullanıcı olacak birisi normal kullanıcı, digeri ise admin
Ana sayfada arkadaş ekleme butonu olacak, ve arkadaşların listelendiği bir kısım olacak
Arkadaş ekleme butonuna tıklandığında bir arama ekranı açılacak, arama ekranında Ad soyad ile arama yapma özelliği olacak
Talep gönder butonu olacak talep gönderildiğinde admin onayına gönderildiğine dair bir bildirim olacak
Bu aşamada arkadaş listesinde görünmez.
Admin panelinde bekleyen talepler listelenecek, onaylanacak veya reddedilecek
Her talep için profil fotoğrafı ad ve not olacak buna göre talep gönderme kısmınıda güncelle
Admin onay verdikten sonra kullanıcının ana ekranında yeni arkadaş olarak görünür olacak
Arkadaş listesine otomatik eklenir.
Normal bir kullanıcı sadece onaylanmış arkadaşlarını görür, onaylanmamış reddedilmiş arkadaşlarını görmez.
Talep gönderirken böyle bir kullanıcı olup olmadığının kontrol edilmesi gerekiyor.
Kullanıcı daha önce arkadaş eklediği kişiyi engelleyebilecek, engellenen kişi tekrar arkadaşlık isteği gönderemeyecek taki engeli kalkana kadar.
Engellenmiş kullanıcılar listesi olmak zorunda.