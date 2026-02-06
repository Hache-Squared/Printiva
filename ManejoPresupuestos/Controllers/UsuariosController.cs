using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace ManejoPresupuestos.Controllers
{
    
    public class UsuariosController : Controller
    {
        private readonly UserManager<Usuario> userManager;      // si lo sigues usando
        private readonly SignInManager<Usuario> signInManager;

        private readonly IRepositorioUsuariosAdmin repoAdmin;
        private readonly IPasswordHasher<Usuario> passwordHasher;
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IServicioPermisos permSvc;

        private static readonly (string Key, string Label)[] PermisosCatalogo = new[]
        {
            ("Clientes", "ClientesController"),
            ("Compras", "ComprasController"),
            ("Cotizaciones", "CotizacionesController"),
            ("Impresoras", "ImpresorasController"),
            ("Inventarios", "InventariosController"),
            ("Pagos", "PagosController"),
            ("Pedidos", "PedidosController"),
            ("Produccion", "ProduccionController"),
            ("Productos", "ProductosController"),
            ("Recetas", "RecetasController"),
            ("Reportes", "ReportesController"),
            ("Tarifas", "TarifasController"),
            ("Usuarios", "UsuariosController")
        };

        public UsuariosController(
            UserManager<Usuario> userManager,
            SignInManager<Usuario> signInManager,
            IRepositorioUsuariosAdmin repoAdmin,
            IPasswordHasher<Usuario> passwordHasher,
            IServicioUsuarios servicioUsuarios,
            IServicioPermisos permSvc
        )
        {
            this.userManager = userManager;
            this.signInManager = signInManager;
            this.repoAdmin = repoAdmin;
            this.passwordHasher = passwordHasher;
            this.servicioUsuarios = servicioUsuarios;
            this.permSvc = permSvc;
        }

        /* =========================
           LOGIN / LOGOUT
           ========================= */

        [HttpGet]
        [AllowAnonymous]
        public IActionResult Login() => View();

        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> Login(LoginViewModel modelo)
        {
            if (!ModelState.IsValid) return View(modelo);

            // bloqueo por EstaActivo
            var usuario = await userManager.FindByEmailAsync(modelo.Email);
            if (usuario is null || !usuario.EstaActivo)
            {
                ModelState.AddModelError(string.Empty, "Usuario no encontrado o desactivado.");
                return View(modelo);
            }

            var resultado = await signInManager.PasswordSignInAsync(usuario, modelo.Password, modelo.Recuerdame, lockoutOnFailure: false);
            if (resultado.Succeeded) return RedirectToAction("Index", "Home");

            ModelState.AddModelError(string.Empty, "Nombre de usuario / password incorrectos");
            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(IdentityConstants.ApplicationScheme);
            return RedirectToAction("Index", "Home");
        }

        /* =========================
           MODULO USUARIOS (ADMIN)
           ========================= */

        [HttpGet]
        [Authorize]
        [Permiso("Usuarios")]
        public async Task<IActionResult> Index()
        {
            var usuarios = await repoAdmin.ListarAsync();
            return View(usuarios);
        }

        [HttpGet]
        [Authorize]
        [Permiso("Usuarios")]
        public async Task<IActionResult> Form(int? id)
        {
            UsuarioFormVm vm;

            if (id.HasValue && id.Value > 0)
            {
                var (u, permisos) = await repoAdmin.ObtenerDetalleAsync(id.Value);
                if (u is null) return NotFound();
                vm = u;
            }
            else
            {
                vm = new UsuarioFormVm();
            }

            vm.PermisosDisponibles = PermisosCatalogo
                .Select(p => new PermisoItemVm
                {
                    Key = p.Key,
                    Label = p.Label,
                    Selected = vm.PermisosSeleccionados.Contains(p.Key, StringComparer.OrdinalIgnoreCase)
                })
                .ToList();

            return PartialView("_UsuarioModal", vm);
        }

        [HttpPost]
        [Authorize]
        [ValidateAntiForgeryToken]
        [Permiso("Usuarios")]
        public async Task<IActionResult> Guardar(UsuarioFormVm vm)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            if (string.IsNullOrWhiteSpace(vm.Nombre)) return Json(new { result = "fail", message = "Nombre requerido." });
            if (string.IsNullOrWhiteSpace(vm.Email)) return Json(new { result = "fail", message = "Email requerido." });

            // password: requerido si es create
            if (vm.Id == 0 && string.IsNullOrWhiteSpace(vm.Password))
                return Json(new { result = "fail", message = "Password requerido para crear." });

            string? passwordHash = null;

            if (!string.IsNullOrWhiteSpace(vm.Password))
            {
                // hash Identity compatible
                var dummyUser = new Usuario { Email = vm.Email };
                passwordHash = passwordHasher.HashPassword(dummyUser, vm.Password);
            }

            var esUpdate = vm.Id > 0;
            var res = await repoAdmin.AlteraAsync(vm, loginId, passwordHash, actualizar: esUpdate, borrar: false, reactivar: false);
            if (res.Result == "success")
            {
                permSvc.Invalidar(res.ElementoId); // create/update (ElementoId trae el id correcto)
            }

            return Json(new { result = res.Result, message = res.Message, elementoId = res.ElementoId });
        }

        [HttpPost]
        [Authorize]
        [ValidateAntiForgeryToken]
        [Permiso("Usuarios")]
        public async Task<IActionResult> CambiarEstado(int id, bool activar)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = new UsuarioFormVm { Id = id };

            var res = await repoAdmin.AlteraAsync(
                vm, loginId,
                passwordHash: null,
                actualizar: false,
                borrar: !activar,
                reactivar: activar
            );

            if (res.Result == "success")
            {
                permSvc.Invalidar(id);
            }

            return Json(new { result = res.Result, message = res.Message });
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult Forbidden(string? returnUrl = null)
        {
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }
    }
}