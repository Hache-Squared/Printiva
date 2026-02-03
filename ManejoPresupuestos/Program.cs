using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Authorization;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);

var politicaUsuariosAutenticados = new AuthorizationPolicyBuilder()
                                    .RequireAuthenticatedUser()
                                    .Build();

// Add services to the container.
builder.Services.AddControllersWithViews(opciones =>
{
    opciones.Filters.Add(new AuthorizeFilter(politicaUsuariosAutenticados));
});

//Es AddTransient porque esta vez no compartiremos datos
builder.Services.AddTransient<IRepositorioTiposCuentas, RepositorioTiposCuentas>();
builder.Services.AddTransient<IServicioUsuarios, ServicioUsuarios>();
builder.Services.AddTransient<IRepositorioCuentas, RepositorioCuentas>();
builder.Services.AddTransient<IRepositorioCategorias, RepositorioCategorias>();
builder.Services.AddTransient<IRepositorioTransacciones, RepositorioTransacciones>();
builder.Services.AddTransient<IRepositorioUsuarios, RepositorioUsuarios>();
builder.Services.AddTransient<IRepositorioInventarioMarcas, RepositorioInventarioMarcas>();
builder.Services.AddTransient<IRepositorioInventarioTipos, RepositorioInventarioTipos>();
builder.Services.AddTransient<IRepositorioInventarioColores, RepositorioInventarioColores>();
builder.Services.AddTransient<IRepositorioInventarioNombres, RepositorioInventarioNombres>();
builder.Services.AddTransient<IRepositorioInventarios, RepositorioInventarios>();
builder.Services.AddTransient<IRepositorioInventarioUnidades, RepositorioInventarioUnidades>();
builder.Services.AddTransient<IRepositorioProductos, RepositorioProductos>();
builder.Services.AddTransient<IRepositorioProductoCategorias, RepositorioProductoCategorias>();
builder.Services.AddTransient<IRepositorioRecetas, RepositorioRecetas>();

builder.Services.AddTransient<IRepositorioFilamentoTipos, RepositorioFilamentoTipos>();
builder.Services.AddTransient<IRepositorioClientes, RepositorioClientes>();


builder.Services.AddTransient<IRepositorioPedidos, RepositorioPedidos>();
builder.Services.AddTransient<IRepositorioClientes, RepositorioClientes>();
builder.Services.AddTransient<IRepositorioPedidoEstatus, RepositorioPedidoEstatus>();

builder.Services.AddTransient<IRepositorioCotizaciones, RepositorioCotizaciones>();
builder.Services.AddTransient<IRepositorioPagos, RepositorioPagos>();
builder.Services.AddTransient<IRepositorioProduccion, RepositorioProduccion>();
builder.Services.AddTransient<IRepositorioImpresoras, RepositorioImpresoras>();

builder.Services.AddTransient<IRepositorioReportes, RepositorioReportes>();
builder.Services.AddTransient<IRepositorioTarifas, RepositorioTarifas>();
builder.Services.AddTransient<IServicioCosteoTarifas, ServicioCosteoTarifas>();
builder.Services.AddTransient<IServicioCotizacionTarifas, ServicioCotizacionTarifas>();

// Program.cs / Startup.cs
builder.Services.AddTransient<IRepositorioComprasV2, RepositorioComprasV2>();
builder.Services.AddTransient<IRepositorioCompraTiposV2, RepositorioCompraTiposV2>();
builder.Services.AddTransient<IRepositorioCompraCategoriasV2, RepositorioCompraCategoriasV2>();

// ya los tienes:
builder.Services.AddTransient<IRepositorioFilamentoTipos, RepositorioFilamentoTipos>();
builder.Services.AddTransient<IRepositorioInventarios, RepositorioInventarios>();
builder.Services.AddTransient<IRepositorioCompraTiposV2, RepositorioCompraTiposV2>();

builder.Services.AddTransient<IRepositorioClientes, RepositorioClientes>();

//configuramos Identity
builder.Services.AddTransient<SignInManager<Usuario>>();

builder.Services.AddTransient<IUserStore<Usuario>, UsuarioStore>();
builder.Services.AddIdentityCore<Usuario>(opciones =>
{
    opciones.Password.RequireDigit = false;
    opciones.Password.RequireLowercase = false;
    opciones.Password.RequireUppercase = false;
    opciones.Password.RequireNonAlphanumeric = false;

}).AddErrorDescriber<MensajesDeErrorIdentity>();

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = IdentityConstants.ApplicationScheme;
    options.DefaultChallengeScheme = IdentityConstants.ApplicationScheme;
    options.DefaultSignOutScheme = IdentityConstants.ApplicationScheme;

}).AddCookie(IdentityConstants.ApplicationScheme, opciones =>
{
    opciones.LoginPath = "/usuarios/login/";
});

//----

builder.Services.AddHttpContextAccessor();
builder.Services.AddTransient<IServicioReportes, ServicioReportes>();

builder.Services.AddAutoMapper(typeof(Program)); //configuramos autoMapper

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();

app.UseAuthorization();


/*
 CUANDO USAMOS 
 /{extra?}/{full?}
    Significa que cuando usemos las etiquetas <a> con el atributo asp-route-extra="extra" o asp-route-full="fua"
    significa que los valores en el enrutamiento se veran afectadas, es decir que el valor sera asignado en la ruta,
    si se usa asp-route-atributo="atributo" este no sera reconocido por la ruta y simplemente sera usado en la ruta directamente como
    /?atributo="atributo" y como con /extra/fua/atributo/
 */
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Reportes}/{action=Index}/{id?}");
//pattern: "{controller=Home}/{action=Index}/{id?}/{extra?}/{full?}");

app.Run();
