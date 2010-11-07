use Unicode::Collate::CJK::Korean;
+{
   overrideCJK => \&Unicode::Collate::CJK::Korean::weightKorean,
};
