using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Models
{
    public class VentaRecetaCreacionViewModel : VentaReceta
    {
        public IEnumerable<SelectListItem> Recetas { get; set; }
    }
}
