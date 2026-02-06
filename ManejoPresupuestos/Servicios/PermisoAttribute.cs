using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Security.Claims;

namespace ManejoPresupuestos.Servicios
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true)]
    public class PermisoAttribute : Attribute, IAsyncAuthorizationFilter
    {
        private readonly string permiso;
        public PermisoAttribute(string permiso) => this.permiso = permiso;

        public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
        {
            var user = context.HttpContext.User;

            if (user?.Identity?.IsAuthenticated != true)
            {
                context.Result = new ChallengeResult();
                return;
            }

            var idClaim = user.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier);
            if (idClaim is null || !int.TryParse(idClaim.Value, out var usuarioId))
            {
                context.Result = new ForbidResult();
                return;
            }

            var svc = context.HttpContext.RequestServices.GetService(typeof(IServicioPermisos)) as IServicioPermisos;
            if (svc is null)
            {
                context.Result = new ForbidResult();
                return;
            }

            if (await svc.EsAdminAsync(usuarioId))
                return;

            var permisos = await svc.ObtenerPermisosAsync(usuarioId);
            if (!permisos.Contains(permiso))
            {
                context.Result = new ForbidResult();
            }
        }
    }
}