object @user
cache @user
node(:data) do |obj|
  {
    id: obj.id,
    email: obj.email
  }
end
#attributes :id, :email
